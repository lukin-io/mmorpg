import { Controller } from "@hotwired/stimulus"

/**
 * Game Layout Controller
 * Manages the main game layout with floating players panel and chat
 *
 * Layout Structure (matching original):
 * - Top bar (name + vitals + navigation links)
 * - Main content (full width map/city)
 * - Floating players panel (bottom-right corner)
 * - Bottom chat bar (slim strip)
 */
export default class extends Controller {
  static targets = [
    "mainContent",
    "playersPanel",
    "playersList",
    "playersLocation",
    "playersTotal",
    "chatArea",
    "chatInput",
    "chatMessages",
    "worldNavigation",
    "socialResizer",
    "timersToggle",
    "timersPopover",
    "timersBody",
    "helpButton",
    "smilesToggle",
    "smilesToggleMore",
    "smilesPopover",
    "chatFilter",
    "chatSpeed",
    "chatTranslit",
    "actionCheck",
    "actionPanel",
    "actionNick",
    "actionLinks"
  ]

  static values = {
    playersSort: { type: String, default: "az" },
    autoRefresh: { type: Boolean, default: true },
    persistKey: { type: String, default: "browser_rpg_layout" },
    encounterUrl: String,
    encounterInterval: { type: Number, default: 30000 },
    socialHeightMin: { type: Number, default: 96 },
    socialHeightMaxRatio: { type: Number, default: 0.58 },
    chatFilter: { type: String, default: "all" },
    chatRefreshMs: { type: Number, default: 10000 },
    translit: { type: Boolean, default: false }
  }

  // Auto-refresh interval
  refreshInterval = null
  chatRefreshInterval = null
  encounterCheckTimer = null
  encounterCheckPending = false
  socialHeightPx = null
  resizingSocial = false
  resizeStartY = 0
  resizeStartHeight = 0
  chatFilterObserver = null

  connect() {
    this.boundPointerMove = this.onSocialResizeMove.bind(this)
    this.boundPointerUp = this.onSocialResizeEnd.bind(this)
    this.boundWindowResize = this.onWindowResize.bind(this)
    this.boundFrameLoad = this.onChatFrameLoad.bind(this)
    this.loadPreferences()
    this.applySocialHeight(this.socialHeightPx ?? this.defaultSocialHeight())
    window.addEventListener("resize", this.boundWindowResize)
    this.setupAutoRefresh()
    this.setupChatRefresh()
    this.setupChatFilterObserver()
    this.applyChatFilter()
    this.syncChatToolLabels()
    this.setupEncounterChecks()
  }

  disconnect() {
    this.stopAutoRefresh()
    this.stopChatRefresh()
    this.stopEncounterChecks()
    this.teardownChatFilterObserver()
    this.onSocialResizeEnd()
    window.removeEventListener("resize", this.boundWindowResize)
    this.chatMessagesTarget?.removeEventListener?.("turbo:frame-load", this.boundFrameLoad)
    this.playersRequestController?.abort()
    this.encounterRequestController?.abort()
    this.encounterRequestController = null
    this.encounterCheckPending = false
  }

  updateWorldMovementState(event) {
    this.worldNavigationTargets.forEach((button) => {
      button.disabled = event.detail.locked === true
    })
  }

  updateLocalChatContext(event) {
    if (!this.hasChatInputTarget) return

    const field = this.chatInputTarget.form?.elements.namedItem("context_key")
    if (field) field.value = event.detail.key
  }

  // =====================
  // PLAYERS PANEL
  // =====================

  sortPlayers(event) {
    event.preventDefault()
    const sortType = event.currentTarget.dataset.sort
    if (!sortType) return

    this.playersSortValue = sortType
    this.savePreferences()

    // Request sorted player list via Turbo
    this.refreshPlayersList()
  }

  toggleAutoRefresh(event) {
    this.autoRefreshValue = event.target.checked
    this.savePreferences()

    if (this.autoRefreshValue) {
      this.setupAutoRefresh()
    } else {
      this.stopAutoRefresh()
    }
  }

  setupAutoRefresh() {
    if (this.refreshInterval) return
    if (!this.autoRefreshValue) return

    // Refresh players list every 30 seconds
    this.refreshInterval = setInterval(() => {
      this.refreshPlayersList()
    }, 30000)
  }

  stopAutoRefresh() {
    if (this.refreshInterval) {
      clearInterval(this.refreshInterval)
      this.refreshInterval = null
    }
  }

  refreshPlayersList() {
    // Turbo-fetch updated players list
    const url = `/world/players?sort=${this.playersSortValue}`

    if (this.hasPlayersListTarget) {
      this.playersRequestController?.abort()
      const requestController = new AbortController()
      this.playersRequestController = requestController
      fetch(url, {
        signal: requestController.signal,
        headers: {
          "Accept": "text/vnd.turbo-stream.html, text/html",
          "X-Requested-With": "XMLHttpRequest"
        }
      })
      .then(response => {
        if (!response.ok) throw new Error(`Presence refresh failed (${response.status})`)

        return response.text()
      })
      .then(html => {
        if (!requestController.signal.aborted && this.element.isConnected && this.hasPlayersListTarget) {
          this.playersListTarget.innerHTML = html
          const snapshot = this.playersListTarget.querySelector("[data-player-list-count]")
          if (snapshot && this.hasPlayersLocationTarget) {
            this.playersLocationTarget.textContent = `${snapshot.dataset.playerListLocation} [ ${snapshot.dataset.playerListCount} ]`
          }
          if (snapshot && this.hasPlayersTotalTarget) {
            this.playersTotalTarget.textContent = `Total [ ${snapshot.dataset.playerListTotal} ]`
          }
        }
      })
      .catch(err => {
        if (err.name !== "AbortError") console.warn("Failed to refresh players:", err)
      })
      .finally(() => {
        if (this.playersRequestController === requestController) this.playersRequestController = null
      })
    }
  }

  // =====================
  // WILDERNESS ENCOUNTERS
  // =====================

  setupEncounterChecks() {
    if (!this.hasEncounterUrlValue || this.encounterCheckTimer) return

    this.scheduleEncounterCheck(0)
  }

  stopEncounterChecks() {
    if (this.encounterCheckTimer) {
      clearTimeout(this.encounterCheckTimer)
      this.encounterCheckTimer = null
    }
  }

  scheduleEncounterCheck(delayMs) {
    if (!this.element.isConnected) return

    this.stopEncounterChecks()
    this.encounterCheckTimer = setTimeout(() => {
      this.encounterCheckTimer = null
      this.checkWorldEncounter()
    }, Math.max(Number(delayMs) || 0, 0))
  }

  async checkWorldEncounter() {
    if (!this.hasEncounterUrlValue || this.encounterCheckPending || !this.element.isConnected) return

    this.encounterCheckPending = true
    const requestController = new AbortController()
    this.encounterRequestController = requestController
    let nextDelay = this.encounterIntervalValue
    try {
      const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
      const response = await fetch(this.encounterUrlValue, {
        signal: requestController.signal,
        method: "POST",
        credentials: "same-origin",
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken || "",
          "X-Requested-With": "XMLHttpRequest"
        },
        body: "{}"
      })
      if (!response.ok || requestController.signal.aborted || !this.element.isConnected) return

      const data = await response.json()
      if (requestController.signal.aborted || !this.element.isConnected) return
      if (!data.interrupted || !data.redirect_url) {
        nextDelay = Number(data.retry_after_ms) || this.encounterIntervalValue
        return
      }

      nextDelay = null
      this.stopEncounterChecks()
      if (window.Turbo?.visit) {
        window.Turbo.visit(data.redirect_url, { action: "replace" })
      } else {
        window.location.assign(data.redirect_url)
      }
    } catch (error) {
      if (error.name !== "AbortError") console.warn("Failed to check wilderness encounter:", error)
    } finally {
      // An old response must not clear or reschedule a reconnected controller's
      // current request. Aborting is best effort; identity guards the lifecycle.
      if (this.encounterRequestController === requestController) {
        this.encounterRequestController = null
        this.encounterCheckPending = false
        if (nextDelay !== null && this.element.isConnected && this.hasEncounterUrlValue && !this.encounterCheckTimer) {
          this.scheduleEncounterCheck(nextDelay)
        }
      }
    }
  }

  // =====================
  // SOCIAL ROW RESIZE
  // =====================

  startSocialResize(event) {
    if (event.pointerType === "mouse" && event.button !== 0) return

    event.preventDefault()
    this.resizingSocial = true
    this.resizeStartY = event.clientY
    this.resizeStartHeight = this.currentSocialHeight()
    document.body.classList.add("nl-resizing-social")
    window.addEventListener("pointermove", this.boundPointerMove)
    window.addEventListener("pointerup", this.boundPointerUp)
    window.addEventListener("pointercancel", this.boundPointerUp)
    event.currentTarget?.setPointerCapture?.(event.pointerId)
  }

  onSocialResizeMove(event) {
    if (!this.resizingSocial) return

    // Drag the upper border up to grow chat, down to shrink it.
    const nextHeight = this.resizeStartHeight + (this.resizeStartY - event.clientY)
    this.applySocialHeight(nextHeight)
  }

  onSocialResizeEnd() {
    if (!this.resizingSocial && !document.body.classList.contains("nl-resizing-social")) {
      window.removeEventListener("pointermove", this.boundPointerMove)
      window.removeEventListener("pointerup", this.boundPointerUp)
      window.removeEventListener("pointercancel", this.boundPointerUp)
      return
    }

    this.resizingSocial = false
    document.body.classList.remove("nl-resizing-social")
    window.removeEventListener("pointermove", this.boundPointerMove)
    window.removeEventListener("pointerup", this.boundPointerUp)
    window.removeEventListener("pointercancel", this.boundPointerUp)
    this.savePreferences()
  }

  nudgeSocialResize(event) {
    const step = event.shiftKey ? 32 : 16
    if (event.key === "ArrowUp") {
      event.preventDefault()
      this.applySocialHeight(this.currentSocialHeight() + step)
      this.savePreferences()
    } else if (event.key === "ArrowDown") {
      event.preventDefault()
      this.applySocialHeight(this.currentSocialHeight() - step)
      this.savePreferences()
    } else if (event.key === "Home") {
      event.preventDefault()
      this.applySocialHeight(this.maxSocialHeight())
      this.savePreferences()
    } else if (event.key === "End") {
      event.preventDefault()
      this.applySocialHeight(this.socialHeightMinValue)
      this.savePreferences()
    }
  }

  onWindowResize() {
    this.applySocialHeight(this.currentSocialHeight())
  }

  applySocialHeight(px) {
    const clamped = this.clampSocialHeight(px)
    this.socialHeightPx = clamped
    this.element.style.setProperty("--nl-social-height", `${clamped}px`)
    if (this.hasSocialResizerTarget) {
      this.socialResizerTarget.setAttribute("aria-valuenow", String(clamped))
    }
    return clamped
  }

  currentSocialHeight() {
    if (Number.isFinite(this.socialHeightPx)) return this.socialHeightPx

    const raw = getComputedStyle(this.element).getPropertyValue("--nl-social-height").trim()
    const parsed = Number.parseFloat(raw)
    return Number.isFinite(parsed) ? parsed : this.defaultSocialHeight()
  }

  defaultSocialHeight() {
    if (window.matchMedia("(max-height: 430px) and (orientation: landscape)").matches) return 120
    if (window.matchMedia("(max-width: 360px)").matches) return 176
    if (window.matchMedia("(max-width: 720px)").matches) return 190
    return 240
  }

  maxSocialHeight() {
    const viewportCap = Math.floor(window.innerHeight * this.socialHeightMaxRatioValue)
    const layoutFloor = 160
    return Math.max(this.socialHeightMinValue + 40, viewportCap - layoutFloor)
  }

  clampSocialHeight(px) {
    const value = Number(px)
    const safe = Number.isFinite(value) ? value : this.defaultSocialHeight()
    return Math.round(Math.min(this.maxSocialHeight(), Math.max(this.socialHeightMinValue, safe)))
  }

  // =====================
  // CHAT
  // =====================

  focusChat() {
    if (this.hasChatInputTarget) this.chatInputTarget.focus()
  }

  sendChat() {
    this.prepareChatSubmit()
    if (this.hasChatInputTarget) this.chatInputTarget.form?.requestSubmit()
  }

  prepareChatSubmit() {
    if (!this.hasChatInputTarget || !this.translitValue) return

    this.chatInputTarget.value = this.transliterate(this.chatInputTarget.value)
  }

  cycleChatFilter(event) {
    event?.preventDefault()
    const order = ["all", "chat", "system"]
    const idx = order.indexOf(this.chatFilterValue)
    this.chatFilterValue = order[(idx + 1) % order.length]
    this.applyChatFilter()
    this.syncChatToolLabels()
    this.savePreferences()
  }

  cycleChatSpeed(event) {
    event?.preventDefault()
    const order = [10000, 30000, 60000, 0]
    const idx = order.indexOf(this.chatRefreshMsValue)
    this.chatRefreshMsValue = order[(idx >= 0 ? idx + 1 : 0) % order.length]
    this.setupChatRefresh()
    this.syncChatToolLabels()
    this.savePreferences()
  }

  toggleTranslit(event) {
    event?.preventDefault()
    this.translitValue = !this.translitValue
    this.syncChatToolLabels()
    this.savePreferences()
  }

  setupChatRefresh() {
    this.stopChatRefresh()
    if (!this.chatRefreshMsValue || this.chatRefreshMsValue <= 0) return

    this.chatRefreshInterval = setInterval(() => {
      this.refreshChat()
    }, this.chatRefreshMsValue)
  }

  stopChatRefresh() {
    if (this.chatRefreshInterval) {
      clearInterval(this.chatRefreshInterval)
      this.chatRefreshInterval = null
    }
  }

  setupChatFilterObserver() {
    if (!this.hasChatMessagesTarget) return

    this.chatMessagesTarget.addEventListener("turbo:frame-load", this.boundFrameLoad)
    if (typeof MutationObserver === "undefined") return

    this.chatFilterObserver = new MutationObserver(() => this.applyChatFilter())
    this.chatFilterObserver.observe(this.chatMessagesTarget, { childList: true, subtree: true })
  }

  teardownChatFilterObserver() {
    this.chatFilterObserver?.disconnect()
    this.chatFilterObserver = null
  }

  onChatFrameLoad() {
    this.applyChatFilter()
  }

  applyChatFilter() {
    if (!this.hasChatMessagesTarget) return

    const mode = this.chatFilterValue
    this.chatMessagesTarget.querySelectorAll(".chat-msg, .game-event").forEach((node) => {
      const isSystem = node.classList.contains("chat-msg--system") || node.classList.contains("game-event")
      let show = true
      if (mode === "chat") show = !isSystem
      if (mode === "system") show = isSystem
      node.hidden = !show
    })
  }

  syncChatToolLabels() {
    if (this.hasChatFilterTarget) {
      const labels = {
        all: this.chatFilterTarget.dataset.labelAll,
        chat: this.chatFilterTarget.dataset.labelChat,
        system: this.chatFilterTarget.dataset.labelSystem
      }
      const label = labels[this.chatFilterValue] || labels.all
      this.chatFilterTarget.textContent = label
      this.chatFilterTarget.title = label
      this.chatFilterTarget.setAttribute("aria-label", label)
    }

    if (this.hasChatSpeedTarget) {
      const ms = this.chatRefreshMsValue
      let key = "off"
      let text = "off"
      if (ms === 10000) { key = "10"; text = "10s" }
      else if (ms === 30000) { key = "30"; text = "30s" }
      else if (ms === 60000) { key = "60"; text = "60s" }
      const label = this.chatSpeedTarget.getAttribute(`data-label-${key}`) || text
      this.chatSpeedTarget.textContent = text
      this.chatSpeedTarget.title = label
      this.chatSpeedTarget.setAttribute("aria-label", label)
    }

    if (this.hasChatTranslitTarget) {
      const on = this.translitValue
      const label = on ? this.chatTranslitTarget.dataset.labelOn : this.chatTranslitTarget.dataset.labelOff
      this.chatTranslitTarget.title = label
      this.chatTranslitTarget.setAttribute("aria-label", label)
      this.chatTranslitTarget.setAttribute("aria-pressed", on ? "true" : "false")
      this.chatTranslitTarget.classList.toggle("nl-chat-tool--active", on)
    }
  }

  transliterate(text) {
    const en = "`qwertyuiop[]asdfghjkl;'zxcvbnm,./~QWERTYUIOP{}ASDFGHJKL:\"ZXCVBNM<>?"
    const ru = "ёйцукенгшщзхъфывапролджэячсмитьбю.ЁЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ,"
    let out = ""
    for (const ch of String(text)) {
      const ei = en.indexOf(ch)
      if (ei >= 0) {
        out += ru[ei]
        continue
      }
      const ri = ru.indexOf(ch)
      if (ri >= 0) {
        out += en[ri]
        continue
      }
      out += ch
    }
    return out
  }

  async requestLocationHelp(event) {
    event?.preventDefault()
    const button = event?.currentTarget || (this.hasHelpButtonTarget ? this.helpButtonTarget : null)
    const url = button?.dataset?.locationHelpUrl
    if (!url) return

    if (button) button.disabled = true
    try {
      const token = document.querySelector('meta[name="csrf-token"]')?.content
      const response = await fetch(url, {
        method: "POST",
        headers: {
          Accept: "application/json",
          "X-Requested-With": "XMLHttpRequest",
          "X-CSRF-Token": token || ""
        },
        credentials: "same-origin"
      })
      if (response.status === 429) return
      if (!response.ok) throw new Error("help failed")
      // Turbo Stream append may land; also refresh local frame as a safe fallback.
      this.refreshChat()
    } catch (_error) {
      // Keep shell quiet — help is optional UX, not a gameplay mutation the player must retry.
    } finally {
      if (button) {
        window.setTimeout(() => {
          button.disabled = false
        }, 1200)
      }
    }
  }

  whisperTo(event) {
    event.preventDefault()
    const username = event.currentTarget.dataset.username
    if (!username || !this.hasChatInputTarget) return

    this.chatInputTarget.value = `%<${username}> `
    this.chatInputTarget.focus()
  }

  async toggleTimers(event) {
    event?.preventDefault()
    if (!this.hasTimersPopoverTarget) return

    const open = this.timersPopoverTarget.hasAttribute("hidden")
    if (!open) {
      this.timersPopoverTarget.hidden = true
      return
    }

    this.timersPopoverTarget.hidden = false
    if (this.hasTimersBodyTarget) {
      this.timersBodyTarget.textContent = "…"
      try {
        const response = await fetch("/character/timers", {
          headers: { Accept: "application/json", "X-Requested-With": "XMLHttpRequest" },
          credentials: "same-origin"
        })
        if (!response.ok) throw new Error("timers failed")
        const data = await response.json()
        const rows = Array.isArray(data.timers) ? data.timers : []
        if (rows.length === 0) {
          this.timersBodyTarget.textContent = data.empty || "—"
        } else {
          this.timersBodyTarget.innerHTML = rows
            .map((row) => `<div class="nl-timer-row"><strong>${row.name}</strong> — ${row.label}</div>`)
            .join("")
        }
      } catch (_error) {
        this.timersBodyTarget.textContent = "…"
      }
    }
  }

  clearChatInput() {
    if (!this.hasChatInputTarget) return

    this.chatInputTarget.value = ""
    this.chatInputTarget.focus()
  }

  toggleSmiles(event) {
    event?.preventDefault()
    if (!this.hasSmilesPopoverTarget) return

    const open = this.smilesPopoverTarget.hasAttribute("hidden")
    if (!open) {
      this.closeSmiles()
      return
    }

    const set = String(event?.currentTarget?.dataset?.smilesSet || "1")
    this.smilesPopoverTarget.querySelectorAll("[data-smiles-set]").forEach((row) => {
      row.hidden = row.dataset.smilesSet !== set
    })
    this.smilesPopoverTarget.hidden = false
    if (this.hasSmilesToggleTarget) this.smilesToggleTarget.setAttribute("aria-expanded", "true")
    if (this.hasSmilesToggleMoreTarget) this.smilesToggleMoreTarget.setAttribute("aria-expanded", "true")
  }

  closeSmiles() {
    if (!this.hasSmilesPopoverTarget) return
    this.smilesPopoverTarget.hidden = true
    if (this.hasSmilesToggleTarget) this.smilesToggleTarget.setAttribute("aria-expanded", "false")
    if (this.hasSmilesToggleMoreTarget) this.smilesToggleMoreTarget.setAttribute("aria-expanded", "false")
  }

  insertSmile(event) {
    event?.preventDefault()
    const code = event?.currentTarget?.dataset?.smileCode
    if (!code || !this.hasChatInputTarget) return

    const field = this.chatInputTarget
    const start = field.selectionStart ?? field.value.length
    const end = field.selectionEnd ?? field.value.length
    const before = field.value.slice(0, start)
    const after = field.value.slice(end)
    const spacer = before.length === 0 || before.endsWith(" ") ? "" : " "
    const insert = `${spacer}${code} `
    field.value = `${before}${insert}${after}`
    const caret = before.length + insert.length
    field.setSelectionRange(caret, caret)
    field.focus()
    this.closeSmiles()
  }

  refreshChat() {
    if (!this.hasChatMessagesTarget) return

    const frame = this.chatMessagesTarget.querySelector("turbo-frame")
    if (!frame?.src) return

    const source = frame.src
    frame.removeAttribute("src")
    frame.src = source
  }

  clearChat() {
    this.chatMessagesTarget.querySelector('[data-controller~="chat"]')
      ?.dispatchEvent(new CustomEvent("chat:clear"))
  }

  // =====================
  // PERSISTENCE
  // =====================

  loadPreferences() {
    try {
      const saved = localStorage.getItem(this.persistKeyValue)
      if (saved) {
        const prefs = JSON.parse(saved)
        if (prefs.playersSort) this.playersSortValue = prefs.playersSort
        if (typeof prefs.autoRefresh === "boolean") this.autoRefreshValue = prefs.autoRefresh
        if (Number.isFinite(prefs.socialHeight)) this.socialHeightPx = prefs.socialHeight
        if (["all", "chat", "system"].includes(prefs.chatFilter)) this.chatFilterValue = prefs.chatFilter
        if ([0, 10000, 30000, 60000].includes(prefs.chatRefreshMs)) this.chatRefreshMsValue = prefs.chatRefreshMs
        if (typeof prefs.translit === "boolean") this.translitValue = prefs.translit
      }
    } catch (e) {
      console.warn("Failed to load layout preferences:", e)
    }
  }

  savePreferences() {
    try {
      const prefs = {
        playersSort: this.playersSortValue,
        autoRefresh: this.autoRefreshValue,
        socialHeight: this.currentSocialHeight(),
        chatFilter: this.chatFilterValue,
        chatRefreshMs: this.chatRefreshMsValue,
        translit: this.translitValue
      }
      localStorage.setItem(this.persistKeyValue, JSON.stringify(prefs))
    } catch (e) {
      console.warn("Failed to save layout preferences:", e)
    }
  }

  toggleActionPanel() {
    if (!this.hasActionPanelTarget || !this.hasActionCheckTarget) return
    const open = this.actionCheckTarget.checked
    this.actionPanelTarget.hidden = !open
    if (open) this.refreshActionPanel()
  }

  rememberActionNick(username, characterId = null) {
    this._actionNick = username
    this._actionCharacterId = characterId
    if (this.hasActionCheckTarget && this.actionCheckTarget.checked) {
      this.refreshActionPanel()
    }
  }

  refreshActionPanel() {
    if (!this.hasActionNickTarget || !this.hasActionLinksTarget) return
    const nick = this._actionNick
    if (!nick) {
      this.actionNickTarget.textContent = this.element.dataset.actionPanelEmpty || "Select a nick (right-click)"
      this.actionLinksTarget.replaceChildren()
      return
    }

    this.actionNickTarget.textContent = nick
    const whisper = document.createElement("button")
    whisper.type = "button"
    whisper.className = "lbut"
    whisper.textContent = this.element.dataset.chatMenuPrivate || "Private"
    whisper.addEventListener("click", () => {
      if (this.hasChatInputTarget) {
        this.chatInputTarget.value = `to [${nick}] `
        this.chatInputTarget.focus()
      }
    })

    const info = document.createElement("a")
    info.className = "lbut"
    info.href = `/player/${encodeURIComponent(nick)}`
    info.target = "_blank"
    info.rel = "noopener"
    info.textContent = this.element.dataset.chatMenuInfo || "Info"

    this.actionLinksTarget.replaceChildren(whisper, info)

    if (this._actionCharacterId) {
      const form = document.createElement("form")
      form.method = "post"
      form.action = "/world/assault"
      form.className = "nl-assault-form"
      const token = document.querySelector("meta[name='csrf-token']")?.content
      if (token) {
        const csrf = document.createElement("input")
        csrf.type = "hidden"
        csrf.name = "authenticity_token"
        csrf.value = token
        form.appendChild(csrf)
      }
      const defender = document.createElement("input")
      defender.type = "hidden"
      defender.name = "defender_id"
      defender.value = String(this._actionCharacterId)
      form.appendChild(defender)
      const kind = document.createElement("input")
      kind.type = "hidden"
      kind.name = "assault_scroll_kind"
      kind.value = "normal"
      form.appendChild(kind)
      const submit = document.createElement("button")
      submit.type = "submit"
      submit.className = "lbut"
      submit.textContent = this.element.dataset.assaultCta || "Assault"
      form.appendChild(submit)
      this.actionLinksTarget.appendChild(form)
    }

    if (this._actionCharacterId) {
      const invite = document.createElement("form")
      invite.method = "post"
      invite.action = "/world/party_invite"
      invite.className = "nl-party-invite-form"
      const token2 = document.querySelector("meta[name='csrf-token']")?.content
      if (token2) {
        const csrf2 = document.createElement("input")
        csrf2.type = "hidden"
        csrf2.name = "authenticity_token"
        csrf2.value = token2
        invite.appendChild(csrf2)
      }
      const target = document.createElement("input")
      target.type = "hidden"
      target.name = "target_id"
      target.value = String(this._actionCharacterId)
      invite.appendChild(target)
      const inviteBtn = document.createElement("button")
      inviteBtn.type = "submit"
      inviteBtn.className = "lbut"
      inviteBtn.textContent = this.element.dataset.partyInviteCta || "Invite"
      invite.appendChild(inviteBtn)
      this.actionLinksTarget.appendChild(invite)
    }
  }
}

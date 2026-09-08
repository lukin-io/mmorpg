import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "input", "userMenu"]
  static values = {
    autoScroll: { type: Boolean, default: true },
    pollUrl: String,
    sessionKey: String,
    contextKey: String
  }

  connect() {
    this.scrollToBottom()

    this.boundHandleScroll = this.handleScroll.bind(this)
    this.boundCloseUserMenu = this.closeUserMenu.bind(this)

    if (this.hasMessagesTarget) {
      this.messagesTarget.addEventListener("scroll", this.boundHandleScroll)
    }

    document.addEventListener("click", this.boundCloseUserMenu)
    if (this.hasPollUrlValue) this.startLocalChat()
    if (this.hasMessagesTarget) {
      this.observedRows = new WeakSet(this.messagesTarget.querySelectorAll("article[id]"))
      this.timelineObserver = new MutationObserver(records => this.handleTimelineChanges(records))
      this.timelineObserver.observe(this.messagesTarget, { childList: true })
    }
  }

  disconnect() {
    if (this.hasMessagesTarget) {
      this.messagesTarget.removeEventListener("scroll", this.boundHandleScroll)
    }
    document.removeEventListener("click", this.boundCloseUserMenu)
    clearInterval(this.pollTimer)
    this.pollRequest?.abort()
    this.timelineObserver?.disconnect()
    if (this.hasPollUrlValue) this.saveLocalBuffer()
  }

  startLocalChat() {
    this.clearedMessageIds = new Set()
    this.restoreLocalBuffer()
    this.announceContext()
    this.pollLocalChat()
    this.pollTimer = setInterval(() => this.pollLocalChat(), 10000)
  }

  announceContext() {
    const field = this.element.querySelector('input[name="context_key"]')
    if (field) field.value = this.contextKeyValue
    this.dispatch("context", { detail: { key: this.contextKeyValue } })
  }

  async pollLocalChat() {
    if (this.pollRequest) return
    const request = new AbortController()
    this.pollRequest = request
    try {
      const response = await fetch(this.pollUrlValue, {
        signal: request.signal,
        headers: { "Accept": "text/html", "X-Requested-With": "XMLHttpRequest" }
      })
      if (!response.ok) return
      const html = await response.text()
      if (request.signal.aborted || !this.element.isConnected) return

      const fragment = new DOMParser().parseFromString(html, "text/html")
      const snapshot = fragment.querySelector("[data-local-chat-session-key]")
      if (!snapshot) return
      if (snapshot.dataset.localChatSessionKey !== this.sessionKeyValue) {
        this.messagesTarget.querySelectorAll("[data-message-id]").forEach(row => row.remove())
        this.clearedMessageIds.clear()
        this.sessionKeyValue = snapshot.dataset.localChatSessionKey
      }
      this.contextKeyValue = snapshot.dataset.localChatContextKey
      this.announceContext()
      this.mergeRows(snapshot.querySelectorAll("[data-message-id]"))
      this.saveLocalBuffer()
    } catch (error) {
      if (error.name !== "AbortError") console.warn("Local chat refresh failed")
    } finally {
      if (this.pollRequest === request) this.pollRequest = null
    }
  }

  mergeRows(rows) {
    rows.forEach(row => {
      if (this.clearedMessageIds?.has(row.dataset.messageId)) return
      if (!this.messagesTarget.querySelector(`#${CSS.escape(row.id)}`)) {
        this.messagesTarget.append(row.cloneNode(true))
      }
    })
    const entries = [...this.messagesTarget.querySelectorAll("article[id]")]
    entries.sort((left, right) => {
      const leftTime = left.querySelector("time")?.dateTime || ""
      const rightTime = right.querySelector("time")?.dateTime || ""
      return leftTime.localeCompare(rightTime) || left.id.localeCompare(right.id)
    }).forEach(row => this.messagesTarget.append(row))
    this.trimTimeline()
  }

  trimTimeline() {
    const entries = [...this.messagesTarget.querySelectorAll("article[id]")]
    if (entries.length) this.messagesTarget.querySelectorAll(".nl-chat-empty, .chat-empty").forEach(row => row.remove())
    entries.slice(0, Math.max(entries.length - 200, 0)).forEach(row => row.remove())
  }

  restoreLocalBuffer() {
    try {
      const saved = JSON.parse(sessionStorage.getItem("local_chat_buffer") || "null")
      if (saved?.sessionKey !== this.sessionKeyValue) {
        sessionStorage.removeItem("local_chat_buffer")
        return
      }
      const fragment = new DOMParser().parseFromString(saved.html || "", "text/html")
      this.clearedMessageIds = new Set((saved.clearedMessageIds || []).slice(-200).map(String))
      this.messagesTarget.querySelectorAll("[data-message-id]").forEach(row => {
        if (this.clearedMessageIds.has(row.dataset.messageId)) row.remove()
      })
      this.mergeRows(fragment.querySelectorAll("article[data-message-id]"))
    } catch { sessionStorage.removeItem("local_chat_buffer") }
  }

  saveLocalBuffer() {
    if (!this.hasMessagesTarget) return
    this.trimTimeline()
    const html = [...this.messagesTarget.querySelectorAll("article[data-message-id]")]
      .map(row => row.outerHTML).join("")
    try {
      sessionStorage.setItem("local_chat_buffer", JSON.stringify({
        sessionKey: this.sessionKeyValue, html, clearedMessageIds: [...this.clearedMessageIds]
      }))
    } catch {}
  }

  clearMessages() {
    if (!this.hasMessagesTarget) return
    if (this.hasPollUrlValue) {
      this.messagesTarget.querySelectorAll("[data-message-id]").forEach(row => {
        this.clearedMessageIds.add(row.dataset.messageId)
      })
      this.clearedMessageIds = new Set([...this.clearedMessageIds].slice(-200))
    }
    this.messagesTarget.replaceChildren()
    this.hideNewMessageIndicator()
    if (this.hasPollUrlValue) this.saveLocalBuffer()
  }

  handleTimelineChanges(records) {
    let added = false
    records.flatMap(record => [...record.addedNodes]).forEach(row => {
      if (row.nodeType !== Node.ELEMENT_NODE || row.tagName !== "ARTICLE" || this.observedRows.has(row)) return
      this.observedRows.add(row)
      added = true
    })
    this.trimTimeline()
    if (this.hasPollUrlValue) this.saveLocalBuffer()
    if (!added) return
    if (this.autoScrollValue) this.scrollToBottom()
    else this.showNewMessageIndicator()
  }

  handleScroll() {
    const target = this.messagesTarget
    const isAtBottom = target.scrollHeight - target.scrollTop - target.clientHeight < 100
    this.autoScrollValue = isAtBottom

    if (isAtBottom) {
      this.hideNewMessageIndicator()
    }
  }

  scrollToBottom() {
    if (!this.hasMessagesTarget) return

    requestAnimationFrame(() => {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
      this.autoScrollValue = true
    })
  }

  jumpToBottom() {
    this.scrollToBottom()
    this.hideNewMessageIndicator()
  }

  showNewMessageIndicator() {
    const indicator = this.element.querySelector(".new-message-indicator")
    if (indicator) indicator.classList.add("is-visible")
  }

  hideNewMessageIndicator() {
    const indicator = this.element.querySelector(".new-message-indicator")
    if (indicator) indicator.classList.remove("is-visible")
  }

  resetForm(event) {
    if (!event.detail.success) return

    if (this.hasInputTarget) {
      this.inputTarget.value = ""
      this.inputTarget.focus()
    }

    this.scrollToBottom()
  }

  handleKeydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      const form = this.inputTarget.closest("form")
      if (form && this.inputTarget.value.trim()) {
        form.requestSubmit()
      }
    }
  }

  clickUsername(event) {
    event.preventDefault()
    const username = event.currentTarget.dataset.username

    if (this.hasInputTarget) {
      this.inputTarget.value = `%<${username}> `
      this.inputTarget.focus()
    }
  }

  showUserMenu(event) {
    event.preventDefault()
    const username = event.currentTarget.dataset.username

    if (!this.hasUserMenuTarget) return

    const menu = this.userMenuTarget
    menu.style.left = `${event.clientX}px`
    menu.style.top = `${event.clientY}px`

    menu.replaceChildren(...this.buildUserMenuLinks(username))
    menu.classList.add("visible")
    menu.dataset.username = username

    event.stopPropagation()
  }

  buildUserMenuLinks(username) {
    const whisper = document.createElement("a")
    whisper.className = "user-menu-link"
    whisper.dataset.action = "click->chat#whisperTo"
    whisper.dataset.username = username
    whisper.textContent = "Private"
    const info = document.createElement("a")
    info.className = "user-menu-link"
    info.href = `/player/${encodeURIComponent(username)}`
    info.target = "_blank"
    info.rel = "noopener"
    info.textContent = "Info"
    return [whisper, info]
  }

  closeUserMenu(event) {
    if (this.hasUserMenuTarget) {
      if (event && this.userMenuTarget.contains(event.target)) return
      this.userMenuTarget.classList.remove("visible")
    }
  }

  whisperTo(event) {
    event.preventDefault()
    const username = event.currentTarget.dataset.username
    if (this.hasInputTarget) {
      this.inputTarget.value = `%<${username}> `
      this.inputTarget.focus()
    }
    this.closeUserMenu()
  }
}

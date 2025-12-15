import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

/**
 * Turn-based combat controller.
 *
 * Handles:
 * - Attack/block selection with action point tracking
 * - Magic slot activation
 * - Turn submission
 * - Real-time combat updates via ActionCable
 */
export default class extends Controller {
  static targets = [
    "actionPointsUsed",
    "penalty",
    "penaltyValue",
    "submitBtn",
    "combatLog"
  ]

  static values = {
    battleId: Number,
    characterId: Number,
    actionLimit: { type: Number, default: 80 },
    manaLimit: { type: Number, default: 50 }
  }

  // Attack penalties for multiple attacks
  static attackPenalties = [0, 0, 25, 75, 150, 250]

  connect() {
    this.selectedAttacks = []
    this.selectedBlocks = []
    this.selectedMagic = []
    this.actionPointsUsed = 0
    this.manaUsed = 0

    this.subscribeToChannel()
    this.updateActionPoints()
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
    if (this.vitalsSubscription) {
      this.vitalsSubscription.unsubscribe()
    }
  }

  // Subscribe to combat channel for real-time updates
  subscribeToChannel() {
    if (!this.hasBattleIdValue) return

    this.subscription = consumer.subscriptions.create(
      { channel: "BattleChannel", battle_id: this.battleIdValue },
      {
        received: (data) => this.handleCombatUpdate(data)
      }
    )

    // Also subscribe to character vitals channel for HP updates
    if (this.hasCharacterIdValue) {
      this.vitalsSubscription = consumer.subscriptions.create(
        { channel: "VitalsChannel", character_id: this.characterIdValue },
        {
          received: (data) => this.handleVitalsUpdate(data)
        }
      )
    }
  }

  // Handle vitals updates (HP changes from server)
  handleVitalsUpdate(data) {
    if (data.type === "damage" || data.type === "heal") {
      // Update the player participant HP display
      const playerParticipant = document.querySelector('.nl-participant--left')
      if (playerParticipant) {
        const hpFill = playerParticipant.querySelector('.nl-bar-fill--hp')
        const hpText = playerParticipant.querySelector('.nl-hp-text')

        if (hpFill && data.hp_percent !== undefined) {
          hpFill.style.width = `${data.hp_percent}%`
          hpFill.classList.toggle('critical', data.hp_percent < 25)
        }

        if (hpText && data.current_hp !== undefined && data.max_hp !== undefined) {
          const maxLen = data.max_hp.toString().length
          const currentStr = data.current_hp.toString().padStart(maxLen, ' ')
          const maxStr = data.max_hp.toString().padStart(maxLen, ' ')
          hpText.textContent = `  ${currentStr}/${maxStr}`
        }
      }
    }

    if (data.type === "death") {
      this.handlePlayerDeath(data)
    }
  }

  // Handle player death
  handlePlayerDeath(data) {
    const actionPanel = document.querySelector('.nl-action-panel')
    if (actionPanel) {
      actionPanel.innerHTML = `
        <div class="nl-battle-result nl-battle-result--defeat">
          <h2>💀 You Have Fallen!</h2>
          <p>${data.message || "You have been defeated."}</p>
          <a href="/world" class="nl-btn nl-btn-primary">Return to World</a>
        </div>
      `
    }
    this.setControlsEnabled(false)
  }

  // Handle real-time combat updates
  handleCombatUpdate(data) {
    switch (data.type) {
      case 'round_complete':
        this.appendLogEntries(data.log_entries)
        this.updateParticipantVitals(data.participants)
        this.resetSelections()
        break
      case 'vitals_update':
        this.updateParticipantVitals(data.participants)
        break
      case 'battle_end':
        this.handleBattleEnd(data)
        break
      case 'log_entry':
        this.appendLogEntry(data.entry)
        break
    }
  }

  // Update action points display when selections change
  updateActionPoints() {
    let totalCost = 0
    let attackCount = 0

    // Count selected attacks
    document.querySelectorAll('.nl-attack-select').forEach(select => {
      if (select.value && select.value !== '') {
        const cost = parseInt(select.selectedOptions[0]?.dataset?.cost || 0)
        totalCost += cost
        attackCount++
      }
    })

    // Count selected blocks (only one block allowed)
    let blockSelected = false
    document.querySelectorAll('.nl-block-select').forEach(select => {
      if (select.value && select.value !== '') {
        if (!blockSelected) {
          const cost = parseInt(select.selectedOptions[0]?.dataset?.cost || 0)
          totalCost += cost
          blockSelected = true
        } else {
          // Disable other blocks if one is selected
          select.value = ''
        }
      }
    })

    // Count magic slots
    document.querySelectorAll('.nl-magic-slot.nl-magic-slot--active').forEach(slot => {
      const cost = parseInt(slot.dataset.cost || 0)
      totalCost += cost
    })

    // Add attack penalty
    const penalty = this.constructor.attackPenalties[attackCount] || 0
    if (penalty > 0) {
      totalCost += penalty
      if (this.hasPenaltyTarget) {
        this.penaltyTarget.style.display = 'inline'
        this.penaltyValueTarget.textContent = penalty
      }

      const penaltyNotice = document.getElementById('penalty-notice')
      if (penaltyNotice) {
        penaltyNotice.style.display = 'block'
        document.getElementById('penalty-amount').textContent = penalty
      }
    } else {
      if (this.hasPenaltyTarget) {
        this.penaltyTarget.style.display = 'none'
      }

      const penaltyNotice = document.getElementById('penalty-notice')
      if (penaltyNotice) {
        penaltyNotice.style.display = 'none'
      }
    }

    this.actionPointsUsed = totalCost

    // Update display
    if (this.hasActionPointsUsedTarget) {
      this.actionPointsUsedTarget.textContent = totalCost

      // Highlight if over limit
      if (totalCost > this.actionLimitValue) {
        this.actionPointsUsedTarget.classList.add('nl-ap-exceeded')
        this.actionPointsUsedTarget.innerHTML = `<span style="color: #cc0000;">${totalCost}</span> <strong>EXCEEDED!</strong>`
      } else {
        this.actionPointsUsedTarget.classList.remove('nl-ap-exceeded')
        this.actionPointsUsedTarget.textContent = totalCost
      }
    }

    // Disable submit if over limit
    if (this.hasSubmitBtnTarget) {
      this.submitBtnTarget.disabled = totalCost > this.actionLimitValue
    }
  }

  // Toggle magic slot selection
  toggleMagicSlot(event) {
    const slot = event.currentTarget
    const isActive = slot.classList.contains('nl-magic-slot--active')

    if (isActive) {
      slot.classList.remove('nl-magic-slot--active')
      slot.style.borderColor = '#cccccc'
    } else {
      slot.classList.add('nl-magic-slot--active')
      slot.style.borderColor = '#cc0000'
    }

    this.updateActionPoints()
  }

  // Reset all selections
  resetSelections() {
    // Clear attack selects
    document.querySelectorAll('.nl-attack-select').forEach(select => {
      select.selectedIndex = 0
    })

    // Clear block selects
    document.querySelectorAll('.nl-block-select').forEach(select => {
      select.selectedIndex = 0
    })

    // Clear magic slots
    document.querySelectorAll('.nl-magic-slot--active').forEach(slot => {
      slot.classList.remove('nl-magic-slot--active')
      slot.style.borderColor = '#cccccc'
    })

    // Re-enable all selects
    document.querySelectorAll('.nl-action-select').forEach(select => {
      select.disabled = false
    })

    this.updateActionPoints()
  }

  // Submit the turn
  submitTurn(event) {
    event.preventDefault()

    if (this.actionPointsUsed > this.actionLimitValue) {
      alert('Action point limit exceeded! Please reduce your selections.')
      return
    }

    // Collect selected actions
    const attacks = []
    document.querySelectorAll('.nl-attack-select').forEach((select, index) => {
      if (select.value && select.value !== '') {
        attacks.push({
          body_part: select.dataset.bodyPart,
          action_key: select.value,
          slot_index: index
        })
      }
    })

    const blocks = []
    document.querySelectorAll('.nl-block-select').forEach((select, index) => {
      if (select.value && select.value !== '') {
        blocks.push({
          body_part: select.dataset.bodyPart,
          action_key: select.value,
          slot_index: index
        })
      }
    })

    const skills = []
    document.querySelectorAll('.nl-magic-slot--active').forEach(slot => {
      skills.push({
        key: slot.dataset.skillKey,
        cost: parseInt(slot.dataset.cost || 0),
        mana: parseInt(slot.dataset.mana || 0)
      })
    })

    // Validate at least some action selected
    if (attacks.length === 0 && blocks.length === 0 && skills.length === 0) {
      alert('Please select at least one action!')
      return
    }

    // Disable controls while submitting
    this.setControlsEnabled(false)

    // Submit via fetch with turbo-stream support
    const formData = new FormData()
    formData.append('action_type', 'turn')
    formData.append('attacks', JSON.stringify(attacks))
    formData.append('blocks', JSON.stringify(blocks))
    formData.append('skills', JSON.stringify(skills))

    fetch(`/combat/action`, {
      method: 'POST',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content,
        'Accept': 'text/vnd.turbo-stream.html, text/html, application/xhtml+xml'
      }
    })
    .then(response => {
      const contentType = response.headers.get('content-type') || ''

      // Handle turbo-stream response
      if (contentType.includes('turbo-stream')) {
        return response.text().then(html => {
          // Let Turbo process the stream
          Turbo.renderStreamMessage(html)
          this.setControlsEnabled(true)
          this.resetSelections()
          return { success: true, turboStream: true }
        })
      }

      // Handle JSON response (error cases)
      if (contentType.includes('json')) {
        return response.json()
      }

      // Default: assume success for other responses
      this.setControlsEnabled(true)
      return { success: true }
    })
    .then(data => {
      if (data.turboStream) {
        // Already handled above
        return
      }

      if (!data.success) {
        alert(data.message || 'Failed to submit turn')
        this.setControlsEnabled(true)
      }
    })
    .catch(error => {
      console.error('Submit error:', error)
      alert('Failed to submit turn. Please try again.')
      this.setControlsEnabled(true)
    })
  }

  // Surrender from battle
  surrender() {
    if (!confirm('Are you sure you want to surrender?')) {
      return
    }

    fetch(`/combat/surrender`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
      },
      body: JSON.stringify({ battle_id: this.battleIdValue })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        window.location.href = '/world'
      } else {
        alert(data.message || 'Failed to surrender')
      }
    })
  }

  // Refresh battle state
  refresh() {
    window.location.reload()
  }

  // Show waiting message
  showWaitingMessage() {
    const actionPanel = document.querySelector('.nl-action-panel')
    if (actionPanel) {
      actionPanel.innerHTML = `
        <div class="nl-waiting-message">
          <span style="color: #CC0000;"><strong>Waiting for opponent's turn...</strong></span>
        </div>
      `
    }
  }

  // Set controls enabled/disabled
  setControlsEnabled(enabled) {
    document.querySelectorAll('.nl-action-select').forEach(select => {
      select.disabled = !enabled
    })

    document.querySelectorAll('.nl-magic-slot').forEach(slot => {
      slot.style.pointerEvents = enabled ? 'auto' : 'none'
    })

    if (this.hasSubmitBtnTarget) {
      this.submitBtnTarget.disabled = !enabled
    }
  }

  // Append log entries to combat log
  appendLogEntries(entries) {
    if (!this.hasCombatLogTarget || !entries) return

    entries.forEach(entry => {
      this.appendLogEntry(entry)
    })

    // Scroll to bottom
    this.combatLogTarget.scrollTop = this.combatLogTarget.scrollHeight
  }

  // Append single log entry
  appendLogEntry(entry) {
    if (!this.hasCombatLogTarget) return

    const table = this.combatLogTarget.querySelector('.nl-log-table')
    if (!table) return

    const row = document.createElement('tr')
    const cell = document.createElement('td')
    cell.className = `nl-log-entry nl-log-${entry.type || 'system'}`

    const time = new Date().toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: false })
    cell.innerHTML = `<span class="nl-log-time">${time}</span> ${entry.message}`

    row.appendChild(cell)
    table.appendChild(row)

    // Scroll to bottom
    this.combatLogTarget.scrollTop = this.combatLogTarget.scrollHeight
  }

  // Update participant vitals (HP/MP bars)
  updateParticipantVitals(participants) {
    if (!participants) return

    participants.forEach(p => {
      const hpBar = document.querySelector(`[data-turn-combat-target="hpBar${p.id}"]`)
      const mpBar = document.querySelector(`[data-turn-combat-target="mpBar${p.id}"]`)
      const hpText = document.querySelector(`[data-turn-combat-target="hpText${p.id}"]`)
      const mpText = document.querySelector(`[data-turn-combat-target="mpText${p.id}"]`)

      if (hpBar) {
        const hpPercent = p.max_hp > 0 ? (p.current_hp / p.max_hp * 100) : 0
        hpBar.style.width = `${hpPercent}%`
        hpBar.classList.toggle('critical', hpPercent < 25)
      }

      if (mpBar) {
        const mpPercent = p.max_mp > 0 ? (p.current_mp / p.max_mp * 100) : 0
        mpBar.style.width = `${mpPercent}%`
      }

      if (hpText) {
        hpText.textContent = `  ${String(p.current_hp).padStart(3)}/${String(p.max_hp).padStart(3)}`
      }

      if (mpText) {
        mpText.textContent = `  ${String(p.current_mp).padStart(3)}/${String(p.max_mp).padStart(3)}`
      }

      // Mark as dead if HP is 0
      const participantEl = document.getElementById(`participant-${p.id}`)
      if (participantEl && p.current_hp <= 0) {
        participantEl.classList.add('nl-participant--dead')
      }
    })
  }

  // Handle battle end
  handleBattleEnd(data) {
    // Show victory/defeat message
    const actionPanel = document.querySelector('.nl-action-panel')
    if (actionPanel) {
      const isVictory = data.winner_team === 'alpha' // Assuming player is alpha
      actionPanel.innerHTML = `
        <div class="nl-battle-result nl-battle-result--${isVictory ? 'victory' : 'defeat'}">
          <h2>${isVictory ? '🎉 Victory!' : '💀 Defeat'}</h2>
          <p>${data.message || (isVictory ? 'You have won the battle!' : 'You have been defeated.')}</p>
          ${data.rewards ? `
            <div class="nl-rewards">
              <p>Rewards:</p>
              <ul>
                ${data.rewards.xp ? `<li>+${data.rewards.xp} XP</li>` : ''}
                ${data.rewards.gold ? `<li>+${data.rewards.gold} Gold</li>` : ''}
              </ul>
            </div>
          ` : ''}
          <a href="/world" class="nl-btn nl-btn-primary">Return to World</a>
        </div>
      `
    }
  }
}


import { Controller } from "@hotwired/stimulus"

/**
 * Quest Dialog Controller
 * Handles step-by-step quest dialog UI with NPC avatars
 * Inspired by Neverlands' quest dialog system
 *
 * Features:
 * - Multi-step dialog navigation
 * - NPC avatar display
 * - Choice selection
 * - Quest acceptance/completion actions
 * - Typewriter text effect
 */
export default class extends Controller {
  static targets = [
    "dialogContent",
    "dialogText",
    "npcAvatar",
    "npcName",
    "stepIndicator",
    "prevButton",
    "nextButton",
    "acceptButton",
    "completeButton",
    "choicesContainer",
    "overlay"
  ]

  static values = {
    questId: Number,
    questAssignmentId: Number,
    currentStep: { type: Number, default: 0 },
    totalSteps: { type: Number, default: 1 },
    canAccept: { type: Boolean, default: false },
    canComplete: { type: Boolean, default: false },
    typewriterSpeed: { type: Number, default: 30 }
  }

  // Dialog state
  steps = []
  typewriterInterval = null

  connect() {
    this.parseSteps()
    this.showStep(this.currentStepValue)
    this.updateNavigationButtons()
  }

  disconnect() {
    this.stopTypewriter()
  }

  // === STEP PARSING ===

  parseSteps() {
    // Parse steps from data attribute or DOM
    const stepsData = this.element.dataset.questDialogSteps
    if (stepsData) {
      try {
        this.steps = JSON.parse(stepsData)
        this.totalStepsValue = this.steps.length
      } catch (e) {
        console.error("Failed to parse quest steps:", e)
        this.steps = []
      }
    }
  }

  // === NAVIGATION ===

  previousStep() {
    if (this.currentStepValue > 0) {
      this.currentStepValue--
      this.showStep(this.currentStepValue)
    }
  }

  nextStep() {
    if (this.currentStepValue < this.totalStepsValue - 1) {
      this.currentStepValue++
      this.showStep(this.currentStepValue)
    }
  }

  goToStep(event) {
    const step = parseInt(event.params?.step ?? event.target.dataset.step, 10)
    if (step >= 0 && step < this.totalStepsValue) {
      this.currentStepValue = step
      this.showStep(step)
    }
  }

  showStep(stepIndex) {
    const step = this.steps[stepIndex]
    if (!step) return

    // Stop any current typewriter
    this.stopTypewriter()

    // Update NPC info
    if (this.hasNpcAvatarTarget && step.npc_avatar) {
      this.npcAvatarTarget.src = step.npc_avatar
      this.npcAvatarTarget.alt = step.npc_name || "NPC"
    }

    if (this.hasNpcNameTarget && step.npc_name) {
      this.npcNameTarget.textContent = step.npc_name
    }

    // Update dialog text with typewriter effect
    if (this.hasDialogTextTarget) {
      if (step.typewriter !== false) {
        this.typewriterEffect(step.text || "")
      } else {
        this.dialogTextTarget.innerHTML = step.text || ""
      }
    }

    // Show/hide choices
    this.updateChoices(step.choices)

    // Update step indicator
    this.updateStepIndicator()

    // Update navigation buttons
    this.updateNavigationButtons()
  }

  // === TYPEWRITER EFFECT ===

  typewriterEffect(text) {
    this.stopTypewriter()

    if (!this.hasDialogTextTarget) return

    this.dialogTextTarget.textContent = ""
    let charIndex = 0
    const displayText = this.stripHtml(text)

    this.typewriterInterval = setInterval(() => {
      if (charIndex < displayText.length) {
        this.dialogTextTarget.textContent += displayText.charAt(charIndex)
        charIndex++
      } else {
        this.stopTypewriter()
        // After typewriter completes, show full HTML content
        this.dialogTextTarget.innerHTML = text
      }
    }, this.typewriterSpeedValue)
  }

  stopTypewriter() {
    if (this.typewriterInterval) {
      clearInterval(this.typewriterInterval)
      this.typewriterInterval = null
    }
  }

  skipTypewriter() {
    if (this.typewriterInterval) {
      this.stopTypewriter()
      const step = this.steps[this.currentStepValue]
      if (step && this.hasDialogTextTarget) {
        this.dialogTextTarget.innerHTML = step.text || ""
      }
    }
  }

  stripHtml(html) {
    const tmp = document.createElement("div")
    tmp.innerHTML = html
    return tmp.textContent || tmp.innerText || ""
  }

  // === CHOICES ===

  updateChoices(choices) {
    if (!this.hasChoicesContainerTarget) return

    this.choicesContainerTarget.innerHTML = ""

    if (!choices || choices.length === 0) {
      this.choicesContainerTarget.style.display = "none"
      return
    }

    this.choicesContainerTarget.style.display = "block"

    choices.forEach((choice, index) => {
      const button = document.createElement("button")
      button.className = "quest-dialog-choice game-btn"
      button.textContent = choice.text
      button.dataset.action = "click->quest-dialog#selectChoice"
      button.dataset.questDialogChoiceIndexParam = index
      button.dataset.questDialogChoiceKeyParam = choice.key || index

      if (choice.disabled) {
        button.disabled = true
        button.classList.add("game-btn--disabled")
      }

      if (choice.requires_item && !choice.has_item) {
        button.classList.add("quest-choice--missing-item")
        button.title = `Requires: ${choice.requires_item}`
      }

      this.choicesContainerTarget.appendChild(button)
    })
  }

  selectChoice(event) {
    const choiceKey = event.params?.choiceKey ?? event.target.dataset.questDialogChoiceKeyParam

    // Dispatch event for handling
    this.dispatch("choiceSelected", {
      detail: {
        questId: this.questIdValue,
        assignmentId: this.questAssignmentIdValue,
        step: this.currentStepValue,
        choiceKey: choiceKey
      }
    })

    // If choice leads to next step, navigate there
    const choice = this.steps[this.currentStepValue]?.choices?.find(c =>
      (c.key || c.index) === choiceKey
    )

    if (choice?.next_step !== undefined) {
      this.currentStepValue = choice.next_step
      this.showStep(this.currentStepValue)
    } else if (choice?.action === "accept") {
      this.acceptQuest()
    } else if (choice?.action === "complete") {
      this.completeQuest()
    } else if (choice?.action === "decline") {
      this.closeDialog()
    }
  }

  // === NAVIGATION BUTTONS ===

  updateNavigationButtons() {
    const isFirst = this.currentStepValue === 0
    const isLast = this.currentStepValue === this.totalStepsValue - 1

    if (this.hasPrevButtonTarget) {
      this.prevButtonTarget.disabled = isFirst
      this.prevButtonTarget.style.visibility = isFirst ? "hidden" : "visible"
    }

    if (this.hasNextButtonTarget) {
      this.nextButtonTarget.disabled = isLast
      this.nextButtonTarget.style.visibility = isLast ? "hidden" : "visible"
    }

    // Show accept/complete buttons on last step
    if (this.hasAcceptButtonTarget) {
      this.acceptButtonTarget.style.display =
        (isLast && this.canAcceptValue) ? "inline-flex" : "none"
    }

    if (this.hasCompleteButtonTarget) {
      this.completeButtonTarget.style.display =
        (isLast && this.canCompleteValue) ? "inline-flex" : "none"
    }
  }

  updateStepIndicator() {
    if (!this.hasStepIndicatorTarget) return

    this.stepIndicatorTarget.textContent =
      `${this.currentStepValue + 1} / ${this.totalStepsValue}`
  }

  // === QUEST ACTIONS ===

  acceptQuest() {
    const form = document.createElement("form")
    form.method = "POST"
    form.action = `/quests/${this.questIdValue}/accept`
    form.style.display = "none"

    const csrfToken = document.querySelector('meta[name="csrf-token"]')
    if (csrfToken) {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = "authenticity_token"
      input.value = csrfToken.content
      form.appendChild(input)
    }

    document.body.appendChild(form)
    form.submit()
  }

  completeQuest() {
    const form = document.createElement("form")
    form.method = "POST"
    form.action = `/quest_assignments/${this.questAssignmentIdValue}/complete`
    form.style.display = "none"

    const csrfToken = document.querySelector('meta[name="csrf-token"]')
    if (csrfToken) {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = "authenticity_token"
      input.value = csrfToken.content
      form.appendChild(input)
    }

    document.body.appendChild(form)
    form.submit()
  }

  // === DIALOG CONTROL ===

  openDialog() {
    this.element.classList.add("quest-dialog--open")
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.add("quest-dialog-overlay--visible")
    }
    document.body.classList.add("quest-dialog-open")
  }

  closeDialog() {
    this.element.classList.remove("quest-dialog--open")
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.remove("quest-dialog-overlay--visible")
    }
    document.body.classList.remove("quest-dialog-open")

    this.dispatch("dialogClosed", {
      detail: { questId: this.questIdValue }
    })
  }

  // Click on overlay to close
  overlayClick(event) {
    if (event.target === this.overlayTarget) {
      this.closeDialog()
    }
  }

  // Keyboard navigation
  handleKeydown(event) {
    switch (event.key) {
      case "ArrowLeft":
        this.previousStep()
        break
      case "ArrowRight":
        this.nextStep()
        break
      case "Enter":
        if (!this.typewriterInterval) {
          // If on last step and can accept/complete, do it
          if (this.currentStepValue === this.totalStepsValue - 1) {
            if (this.canCompleteValue) {
              this.completeQuest()
            } else if (this.canAcceptValue) {
              this.acceptQuest()
            }
          } else {
            this.nextStep()
          }
        } else {
          this.skipTypewriter()
        }
        break
      case "Escape":
        this.closeDialog()
        break
      case " ":
        event.preventDefault()
        this.skipTypewriter()
        break
    }
  }
}

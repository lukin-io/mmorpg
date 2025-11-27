import { Controller } from "@hotwired/stimulus"

/**
 * Clipboard Controller
 *
 * Copies text to clipboard with visual feedback.
 *
 * @example
 *   <button data-controller="clipboard"
 *           data-clipboard-text-value="https://example.com/share/abc123"
 *           data-action="click->clipboard#copy">
 *     🔗 Share
 *   </button>
 */
export default class extends Controller {
  static values = {
    text: String,
    successMessage: { type: String, default: "Copied!" },
    duration: { type: Number, default: 2000 }
  }

  async copy(event) {
    event.preventDefault()

    const text = this.textValue
    if (!text) return

    try {
      await navigator.clipboard.writeText(text)
      this.showSuccess()
    } catch (err) {
      // Fallback for older browsers
      this.fallbackCopy(text)
    }
  }

  fallbackCopy(text) {
    const textarea = document.createElement("textarea")
    textarea.value = text
    textarea.style.position = "fixed"
    textarea.style.left = "-9999px"
    document.body.appendChild(textarea)
    textarea.select()

    try {
      document.execCommand("copy")
      this.showSuccess()
    } catch (err) {
      this.showError()
    }

    document.body.removeChild(textarea)
  }

  showSuccess() {
    const originalText = this.element.textContent
    this.element.textContent = this.successMessageValue
    this.element.classList.add("copied")

    setTimeout(() => {
      this.element.textContent = originalText
      this.element.classList.remove("copied")
    }, this.durationValue)
  }

  showError() {
    const originalText = this.element.textContent
    this.element.textContent = "Failed to copy"
    this.element.classList.add("copy-error")

    setTimeout(() => {
      this.element.textContent = originalText
      this.element.classList.remove("copy-error")
    }, this.durationValue)
  }
}


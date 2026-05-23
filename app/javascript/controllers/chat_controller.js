import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "input", "userMenu"]
  static values = {
    autoScroll: { type: Boolean, default: true }
  }

  connect() {
    this.scrollToBottom()

    this.boundHandleStreamRender = this.handleStreamRender.bind(this)
    this.boundHandleScroll = this.handleScroll.bind(this)
    this.boundCloseUserMenu = this.closeUserMenu.bind(this)

    this.element.addEventListener("turbo:before-stream-render", this.boundHandleStreamRender)

    if (this.hasMessagesTarget) {
      this.messagesTarget.addEventListener("scroll", this.boundHandleScroll)
    }

    document.addEventListener("click", this.boundCloseUserMenu)
  }

  disconnect() {
    this.element.removeEventListener("turbo:before-stream-render", this.boundHandleStreamRender)
    if (this.hasMessagesTarget) {
      this.messagesTarget.removeEventListener("scroll", this.boundHandleScroll)
    }
    document.removeEventListener("click", this.boundCloseUserMenu)
  }

  handleStreamRender() {
    requestAnimationFrame(() => {
      if (this.autoScrollValue) {
        this.scrollToBottom()
      } else {
        this.showNewMessageIndicator()
      }
    })
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
    if (indicator) indicator.classList.add("visible")
  }

  hideNewMessageIndicator() {
    const indicator = this.element.querySelector(".new-message-indicator")
    if (indicator) indicator.classList.remove("visible")
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

    menu.innerHTML = this.buildUserMenuHTML(username)
    menu.classList.add("visible")
    menu.dataset.username = username

    event.stopPropagation()
  }

  buildUserMenuHTML(username) {
    const encodedUsername = encodeURIComponent(username)

    return `
      <a class="user-menu-link" data-action="click->chat#whisperTo" data-username="${username}">
        Private
      </a>
      <a class="user-menu-link" href="/player/${encodedUsername}" target="_blank">
        Info
      </a>
    `
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

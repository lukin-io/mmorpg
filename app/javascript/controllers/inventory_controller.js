import { Controller } from "@hotwired/stimulus"

/**
 * Inventory Controller
 *
 * Handles inventory interactions including:
 * - Item selection
 * - Context menu display
 * - Equipment actions (equip/unequip)
 * - Item usage and discard
 * - Stack splitting
 *
 * Usage:
 *   <div data-controller="inventory">
 *     <div data-action="click->inventory#selectItem" data-item-id="123">
 *     </div>
 *   </div>
 */
export default class extends Controller {
  static targets = ["contextMenu", "selectedItem", "splitModal", "splitQuantity"]

  connect() {
    this.selectedItemId = null
    this.selectedItemElement = null

    // Close context menu on click outside
    document.addEventListener("click", this.handleOutsideClick.bind(this))
    document.addEventListener("keydown", this.handleKeydown.bind(this))
  }

  disconnect() {
    document.removeEventListener("click", this.handleOutsideClick.bind(this))
    document.removeEventListener("keydown", this.handleKeydown.bind(this))
  }

  /**
   * Select an inventory item
   * @param {Event} event - Click event
   */
  selectItem(event) {
    event.preventDefault()
    const element = event.currentTarget
    const itemId = element.dataset.itemId

    // Deselect previous
    if (this.selectedItemElement) {
      this.selectedItemElement.classList.remove("selected")
    }

    // Select new
    this.selectedItemId = itemId
    this.selectedItemElement = element
    element.classList.add("selected")
  }

  /**
   * Show context menu for item
   * @param {Event} event - Right-click event
   */
  showContextMenu(event) {
    event.preventDefault()
    const element = event.currentTarget
    const itemId = element.dataset.itemId

    this.selectedItemId = itemId
    this.selectedItemElement = element

    if (this.hasContextMenuTarget) {
      const menu = this.contextMenuTarget
      menu.style.display = "block"
      menu.style.left = `${event.clientX}px`
      menu.style.top = `${event.clientY}px`
      menu.dataset.itemId = itemId
    }
  }

  /**
   * Hide context menu
   */
  hideContextMenu() {
    if (this.hasContextMenuTarget) {
      this.contextMenuTarget.style.display = "none"
    }
  }

  /**
   * Handle click outside context menu
   * @param {Event} event - Click event
   */
  handleOutsideClick(event) {
    if (this.hasContextMenuTarget && !this.contextMenuTarget.contains(event.target)) {
      this.hideContextMenu()
    }
  }

  /**
   * Handle keyboard shortcuts
   * @param {KeyboardEvent} event - Keyboard event
   */
  handleKeydown(event) {
    if (event.key === "Escape") {
      this.hideContextMenu()
      this.deselectItem()
    }
  }

  /**
   * Deselect current item
   */
  deselectItem() {
    if (this.selectedItemElement) {
      this.selectedItemElement.classList.remove("selected")
      this.selectedItemElement = null
      this.selectedItemId = null
    }
  }

  /**
   * Equip selected item
   * @param {Event} event - Click event
   */
  equipItem(event) {
    event.preventDefault()
    if (!this.selectedItemId) return

    this.hideContextMenu()
    this.submitAction("/inventory/equip", { item_id: this.selectedItemId })
  }

  /**
   * Use selected item (consumables)
   * @param {Event} event - Click event
   */
  useItem(event) {
    event.preventDefault()
    if (!this.selectedItemId) return

    this.hideContextMenu()
    this.submitAction("/inventory/use", { item_id: this.selectedItemId })
  }

  /**
   * Enhance selected item
   * @param {Event} event - Click event
   */
  enhanceItem(event) {
    event.preventDefault()
    if (!this.selectedItemId) return

    this.hideContextMenu()
    // Navigate to enhancement page
    window.Turbo.visit(`/equipment_enhancements/${this.selectedItemId}`)
  }

  /**
   * Show split stack modal
   * @param {Event} event - Click event
   */
  splitStack(event) {
    event.preventDefault()
    if (!this.selectedItemId) return

    this.hideContextMenu()

    if (this.hasSplitModalTarget) {
      this.splitModalTarget.style.display = "block"
    }
  }

  /**
   * Confirm stack split
   * @param {Event} event - Click event
   */
  confirmSplit(event) {
    event.preventDefault()
    if (!this.selectedItemId) return

    const quantity = this.hasSplitQuantityTarget ? this.splitQuantityTarget.value : 1

    this.submitAction("/inventory/split", {
      item_id: this.selectedItemId,
      quantity: quantity
    })

    if (this.hasSplitModalTarget) {
      this.splitModalTarget.style.display = "none"
    }
  }

  /**
   * Discard selected item
   * @param {Event} event - Click event
   */
  discardItem(event) {
    event.preventDefault()
    if (!this.selectedItemId) return

    if (!confirm("Are you sure you want to discard this item?")) {
      return
    }

    this.hideContextMenu()

    // Use DELETE method for destroy action
    const form = document.createElement("form")
    form.method = "POST"
    form.action = `/inventory/items/${this.selectedItemId}`

    const methodInput = document.createElement("input")
    methodInput.type = "hidden"
    methodInput.name = "_method"
    methodInput.value = "DELETE"
    form.appendChild(methodInput)

    const csrfToken = document.querySelector('meta[name="csrf-token"]').content
    const csrfInput = document.createElement("input")
    csrfInput.type = "hidden"
    csrfInput.name = "authenticity_token"
    csrfInput.value = csrfToken
    form.appendChild(csrfInput)

    document.body.appendChild(form)
    form.requestSubmit()
  }

  /**
   * Handle equipment slot click (unequip)
   * @param {Event} event - Click event
   */
  clickEquipmentSlot(event) {
    const slot = event.currentTarget.dataset.slot
    const hasFilled = event.currentTarget.classList.contains("filled")

    if (hasFilled) {
      // Unequip handled by button in template
      return
    }

    // Empty slot - could show equip dialog for that slot type
    console.log(`Empty slot clicked: ${slot}`)
  }

  /**
   * Submit inventory action via Turbo
   * @param {string} action - URL path
   * @param {Object} params - Form parameters
   */
  submitAction(action, params) {
    const form = document.createElement("form")
    form.method = "POST"
    form.action = action
    form.dataset.turbo = "true"

    // Add CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content
    const csrfInput = document.createElement("input")
    csrfInput.type = "hidden"
    csrfInput.name = "authenticity_token"
    csrfInput.value = csrfToken
    form.appendChild(csrfInput)

    // Add parameters
    Object.entries(params).forEach(([key, value]) => {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = key
      input.value = value
      form.appendChild(input)
    })

    document.body.appendChild(form)
    form.requestSubmit()
    document.body.removeChild(form)
  }
}


import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.selectedItemElement = null
    document.addEventListener("keydown", this.handleKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown)
  }

  selectItem(event) {
    const element = event.currentTarget

    if (this.selectedItemElement) {
      this.selectedItemElement.classList.remove("selected")
    }

    this.selectedItemElement = element
    element.classList.add("selected")
  }

  clickEquipmentSlot(event) {
    const slot = event.currentTarget
    if (!slot.classList.contains("filled")) return

    const unequipForm = slot.querySelector("form")
    if (!unequipForm) return

    if (unequipForm.requestSubmit) {
      unequipForm.requestSubmit()
    } else {
      unequipForm.submit()
    }
  }

  handleKeydown = (event) => {
    if (event.key !== "Escape") return

    if (this.selectedItemElement) {
      this.selectedItemElement.classList.remove("selected")
      this.selectedItemElement = null
    }
  }
}

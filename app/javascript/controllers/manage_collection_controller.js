import { Controller } from "@hotwired/stimulus"

// Adds/removes editor rows. The server validates and persists every value.
export default class extends Controller {
  static targets = ["rows", "template", "row"]
  static values = { nextIndex: Number, limit: Number }

  add() {
    if (this.rowTargets.length >= this.limitValue) return

    const fragment = this.templateTarget.content.cloneNode(true)
    for (const element of fragment.querySelectorAll("[name], [id], label[for]")) {
      for (const attribute of ["name", "id", "for"]) {
        if (element.hasAttribute(attribute)) {
          element.setAttribute(attribute, element.getAttribute(attribute).replaceAll("NEW_ROW", this.nextIndexValue))
        }
      }
    }
    this.nextIndexValue += 1
    this.rowsTarget.append(fragment)
  }

  remove(event) {
    event.target.closest('[data-manage-collection-target="row"]')?.remove()
  }
}

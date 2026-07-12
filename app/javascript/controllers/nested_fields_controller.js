import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template"]

  add(event) {
    event.preventDefault()
    const index = new Date().getTime()
    const html = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, index)
    this.containerTarget.insertAdjacentHTML("beforeend", html)
  }

  remove(event) {
    event.preventDefault()
    const fields = event.target.closest(".ingredient-fields")
    const destroyInput = fields.querySelector("input[name*='_destroy']")

    if (destroyInput) {
      destroyInput.value = "1"
      fields.style.display = "none"
    } else {
      fields.remove()
    }
  }
}

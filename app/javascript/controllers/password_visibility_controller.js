import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "toggle"]

  toggle() {
    const isHidden = this.inputTarget.type === "password"
    this.inputTarget.type = isHidden ? "text" : "password"
    this.toggleTarget.textContent = isHidden ? "非表示" : "表示"
    this.toggleTarget.setAttribute("aria-pressed", isHidden)
  }
}

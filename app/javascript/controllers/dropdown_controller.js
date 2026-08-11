import { Controller } from "@hotwired/stimulus"

// Progressive enhancement for a native <details> menu: closes it on an outside click.
// Works via plain <details>/<summary> even if this controller never connects.
export default class extends Controller {
  static targets = ["menu"]

  hide(event) {
    if (!this.menuTarget.contains(event.target)) {
      this.menuTarget.open = false
    }
  }

  connect() {
    this.hideBound = this.hide.bind(this)
    document.addEventListener("click", this.hideBound)
  }

  disconnect() {
    document.removeEventListener("click", this.hideBound)
  }
}

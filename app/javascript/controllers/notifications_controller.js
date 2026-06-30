import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "badge"]

  markAllRead() {
    this.itemTargets.forEach(item => item.classList.add("read"))
    if (this.hasBadgeTarget) {
      this.badgeTarget.textContent = "0"
    }
  }
}

import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="notifications"
// Used on both the dashboard sidebar teaser (item, badge) and the
// full /notifications page (item, badge, chip, count).
export default class extends Controller {
  static targets = ["item", "badge", "chip", "count"]

  markAllRead() {
    this.itemTargets.forEach((item) => {
      item.classList.add("read")
      const btn = item.querySelector(".mark-read--single")
      if (btn) btn.remove()
    })
    if (this.hasBadgeTarget) this.badgeTarget.remove()
    this.updateCount(0)
  }

  markOneRead(event) {
    const item = event.currentTarget.closest("[data-notifications-target='item']")
    if (!item) return
    item.classList.add("read")
    event.currentTarget.remove()
    if (this.hasCountTarget) {
      const remaining = Math.max(this.currentCount() - 1, 0)
      this.updateCount(remaining)
    }
  }

  filter(event) {
    const kind = event.params.kind

    this.chipTargets.forEach((chip) => chip.classList.remove("active"))
    event.currentTarget.classList.add("active")

    this.itemTargets.forEach((item) => {
      const matches = kind === "all" || item.dataset.kind === kind
      item.hidden = !matches
    })
  }

  currentCount() {
    return parseInt(this.countTarget.textContent, 10) || 0
  }

  updateCount(value) {
    if (this.hasCountTarget) this.countTarget.textContent = value
  }
}
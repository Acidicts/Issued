import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="notifications"
// Used on both the dashboard sidebar teaser (item, count, readControl) and the
// full /notifications page (item, count, chip, readControl).
export default class extends Controller {
  static targets = ["item", "count", "chip", "readControl"]

  markAllRead() {
    this.unreadItems.forEach((item) => this.markRead(item))
    this.updateCount(0)
  }

  markOneRead(event) {
    const item = event.currentTarget.closest("[data-notifications-target='item']")
    if (item) this.markRead(item)
    this.updateCount(this.unreadItems.length)
  }

  filter(event) {
    const kind = event.params.kind

    this.chipTargets.forEach((chip) => chip.classList.remove("active"))
    event.currentTarget.classList.add("active")

    this.itemTargets.forEach((item) => {
      const row = item.closest("turbo-frame") || item
      row.hidden = !(kind === "all" || item.dataset.kind === kind)
    })
  }

  get unreadItems() {
    return this.itemTargets.filter((item) => !item.classList.contains("read"))
  }

  markRead(item) {
    if (item.classList.contains("read")) return

    item.classList.add("read")
    item.querySelector("[data-notifications-target='readControl']")?.remove()

    // The read endpoint redirects back, so the response body is of no interest.
    const url = item.dataset.notificationsReadUrlValue
    if (url) fetch(url, { headers: { Accept: "text/html" }, credentials: "same-origin" })
  }

  updateCount(value) {
    if (this.hasCountTarget) this.countTarget.textContent = value
  }
}

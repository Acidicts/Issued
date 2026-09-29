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
    // It is a PATCH (not a GET) because it also persists a reply, and a state
    // change reachable by GET is triggerable from any other site.
    const url = item.dataset.notificationsReadUrlValue
    if (url) {
      fetch(url, {
        method: "PATCH",
        headers: {
          Accept: "text/html",
          "X-Requested-With": "XMLHttpRequest",
          "X-CSRF-Token": this.csrfToken
        },
        credentials: "same-origin"
      })
    }
  }

  get csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content ?? ""
  }

  updateCount(value) {
    if (this.hasCountTarget) this.countTarget.textContent = value
  }
}

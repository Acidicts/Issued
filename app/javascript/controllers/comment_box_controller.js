import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  connect() {
    this.contentTarget.style.overflow = "hidden"
    this.contentTarget.style.transition = "max-height 0.3s ease"
    this.open = false

    this.refreshHeight()

    this.observer = new MutationObserver(() => this.refreshHeight())
    this.observer.observe(this.contentTarget, { childList: true, subtree: true })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  toggle() {
    this.open = !this.open
    this.refreshHeight()
  }

  refreshHeight() {
    this.contentTarget.style.maxHeight = this.open
      ? `${this.contentTarget.scrollHeight}px`
      : "0px"
  }
}
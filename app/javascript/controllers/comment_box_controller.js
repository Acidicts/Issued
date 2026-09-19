import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  connect() {
    this.contentTarget.style.maxHeight = "0px"
    this.contentTarget.style.overflow = "hidden"
    this.contentTarget.style.transition = "max-height 0.3s ease"
    this.open = false
  }

  toggle() {
    if (this.open) {
      this.contentTarget.style.maxHeight = "0px"
    } else {
      this.contentTarget.style.maxHeight = this.contentTarget.scrollHeight + "px"
    }
    this.open = !this.open
  }
}

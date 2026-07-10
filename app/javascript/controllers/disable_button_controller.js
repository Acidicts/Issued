import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { with: String }

  connect() {
    this.button = this.element.querySelector('[type="submit"]')
  }

  disable(event) {
    if (this.button && !this.button.disabled) {
      this.button.disabled = true
      if (this.hasWithValue) {
        this.button.dataset.originalText = this.button.textContent
        this.button.textContent = this.withValue
      }
    }
  }

  disconnect() {
    if (this.button && this.button.disabled) {
      this.button.disabled = false
      if (this.button.dataset.originalText) {
        this.button.textContent = this.button.dataset.originalText
      }
    }
  }
}

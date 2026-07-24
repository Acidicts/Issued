import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["pii", "button"]

  connect() {
    this.originalContent = this.piiTarget.textContent
    this.censoredContent = "*".repeat(this.originalContent.length)
    this.piiTarget.textContent = this.censoredContent
  }

  showClick() {
    if (this.piiTarget.textContent === this.censoredContent) {
      this.show()
    } else {
      this.hide()
    }
  }

  show() {
    this.piiTarget.textContent = this.originalContent
    this.buttonTarget.textContent = "Hide"
  }

  hide() {
    this.piiTarget.textContent = this.censoredContent
    this.buttonTarget.textContent = "Show"
  }
}

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "input", "submitButton", "status"]

  submit() {
    if (!this.hasInputTarget || !this.inputTarget.value.trim()) return

    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = true
      this.submitButtonTarget.value = "Fetching..."
    }

    if (this.hasStatusTarget) {
      this.statusTarget.style.display = "inline"
    }
  }
}

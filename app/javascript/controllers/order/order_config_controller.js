import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["productImage", "radioButton"]

  static values = {
    colorHex: String
  }

  connect() {
    if (this.colorHexValues) {
      this.updateColor(this.colorHexValues)
    }
  }

  updateColorByButton(event) {
    const radio_button = event.target.closest("[data-order--order-config-target='radioButton']")
    if (!radio_button) return
    this.updateColor(radio_button.value)
  }


  updateColor(value) {
    this.productImageTarget.style.backgroundColor = value
  }
}

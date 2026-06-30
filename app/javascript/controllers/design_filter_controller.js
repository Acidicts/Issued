import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["chip", "card"]

  filter(event) {
    const status = event.currentTarget.dataset.designFilterStatusParam
    this.chipTargets.forEach(c => c.classList.remove("active"))
    event.currentTarget.classList.add("active")

    this.cardTargets.forEach(card => {
      if (status === "all" || card.dataset.status === status) {
        card.style.display = ""
      } else {
        card.style.display = "none"
      }
    })
  }
}

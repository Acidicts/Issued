import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab"]

  select(event) {
    this.tabTargets.forEach(t => t.classList.remove("active"))
    event.currentTarget.classList.add("active")
  }
}

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["hours", "minutes", "seconds"]
  static values = {
    seconds: Number
  }

  connect() {
    const existing = parseInt(this.secondsTarget.value, 10)
    if (!isNaN(existing) && existing > 0) {
      this.hoursTarget.value = Math.floor(existing / 3600)
      this.minutesTarget.value = Math.floor((existing % 3600) / 60)
    } else {
      this.hoursTarget.value = Math.floor(this.secondsValue / 3600)
      this.minutesTarget.value = Math.floor((this.secondsValue % 3600) / 60)
    }
    this.recompute()
  }

  recompute() {
    const hours = parseInt(this.hoursTarget.value, 10) || 0
    const minutes = parseInt(this.minutesTarget.value, 10) || 0
    this.secondsTarget.value = (hours * 3600) + (minutes * 60)
  }
}
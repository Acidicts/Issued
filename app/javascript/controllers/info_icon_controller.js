import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tooltip"]

  show() {
    const tooltip = this.tooltipTarget
    const trigger = this.element
    const rect = trigger.getBoundingClientRect()

    tooltip.style.display = "block"

    const tipRect = tooltip.getBoundingClientRect()
    const gap = 8

    let top = rect.top - tipRect.height - gap
    let left = rect.left + (rect.width - tipRect.width) / 2

    if (top < 4) {
      top = rect.bottom + gap
      tooltip.classList.add("brand-info-icon__tooltip--below")
    } else {
      tooltip.classList.remove("brand-info-icon__tooltip--below")
    }

    if (left < 4) left = 4
    if (left + tipRect.width > window.innerWidth - 4) {
      left = window.innerWidth - tipRect.width - 4
    }

    tooltip.style.top = `${top}px`
    tooltip.style.left = `${left}px`
  }

  hide() {
    this.tooltipTarget.style.display = "none"
    this.tooltipTarget.classList.remove("brand-info-icon__tooltip--below")
  }
}

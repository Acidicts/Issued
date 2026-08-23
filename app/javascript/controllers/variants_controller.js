import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template"]

  connect() {
    this.boundColorChange = this.handleColorChange.bind(this)
    this.element.addEventListener("change", this.boundColorChange)
  }

  disconnect() {
    this.element.removeEventListener("change", this.boundColorChange)
  }

  add(event) {
    event.preventDefault()
    const uniqueId = new Date().getTime()
    const newFieldHtml = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, uniqueId)

    this.templateTarget.insertAdjacentHTML("beforebegin", newFieldHtml)
  }

  remove(event) {
    event.preventDefault()
    const card = event.target.closest("[data-variants-card]")
    const destroyInput = card.querySelector(".variants-destroy-flag")
    const groupWrapper = card.closest(".variant-color-dropdown")

    if (destroyInput.value === "" || destroyInput.value === "0") {
      destroyInput.value = "1"
      card.style.display = "none"

      if (groupWrapper) {
        this.updateCount(groupWrapper)
        this.hideIfEmpty(groupWrapper)
      }
    } else {
      card.remove()
      if (groupWrapper) {
        this.updateCount(groupWrapper)
        this.hideIfEmpty(groupWrapper)
      }
    }
  }

  handleColorChange(event) {
    const input = event.target
    if (!input.matches('[aria-label="Color"]')) return

    const card = input.closest("[data-variants-card]")
    if (!card) return

    const newColor = (input.value || "").trim().toLowerCase()
    if (!newColor.match(/^#[0-9a-f]{6}$/)) return

    const currentGroup = card.closest(".variant-color-dropdown")
    const targetGroup = this.findOrCreateGroup(newColor)

    if (currentGroup === targetGroup) return

    const body = targetGroup.querySelector(".variant-color-body")
    body.appendChild(card)

    if (currentGroup) {
      this.updateCount(currentGroup)
      this.hideIfEmpty(currentGroup)
    }
    this.updateCount(targetGroup)
  }

  findOrCreateGroup(colorHex) {
    const normalized = colorHex.trim().toLowerCase()

    const groups = this.element.querySelectorAll(".variant-color-dropdown")
    for (const group of groups) {
      const hex = group.querySelector(".variant-color-hex")?.textContent?.trim().toLowerCase()
      if (hex === normalized) return group
    }

    const groupHtml = `
      <details class="variant-color-dropdown">
        <summary class="variant-color-summary">
          <span class="variant-color-dot" style="background-color: ${normalized};"></span>
          <span class="variant-color-hex">${normalized}</span>
          <span class="variant-color-count">0</span>
        </summary>
        <div class="variant-color-body"></div>
      </details>
    `

    this.templateTarget.insertAdjacentHTML("beforebegin", groupHtml)
    return this.element.querySelector(".variant-color-dropdown:last-of-type")
  }

  updateCount(group) {
    if (!group) return
    const cards = group.querySelectorAll("[data-variants-card]")
    const visibleCount = Array.from(cards).filter(c => getComputedStyle(c).display !== "none").length
    const countEl = group.querySelector(".variant-color-count")
    if (countEl) countEl.textContent = visibleCount
  }

  hideIfEmpty(group) {
    if (!group) return
    const cards = group.querySelectorAll("[data-variants-card]")
    const allHidden = Array.from(cards).every(c => getComputedStyle(c).display === "none")
    if (allHidden) {
      group.removeAttribute("open")
      group.style.display = "none"
    }
  }
}
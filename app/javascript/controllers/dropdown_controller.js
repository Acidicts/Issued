import { Controller } from "@hotwired/stimulus"

// Drives a themed custom listbox on top of a real (visually hidden)
// <select>. The native select stays in the DOM so the form still
// submits normally and screen readers / no-JS fallback still work —
// this controller just layers a matching-look popup on top of it so
// the open state isn't native OS/browser chrome (which can't be
// themed with CSS alone).
//
// Markup expected (see app/assets/stylesheets/components/dropdown.css):
//
//   <div class="dropdown" data-controller="dropdown">
//     <select class="dropdown-select" data-dropdown-target="select" data-action="...">...</select>
//     <button class="dropdown-trigger" data-dropdown-target="trigger" data-action="click->dropdown#toggle">
//       <span data-dropdown-target="label">...</span>
//     </button>
//     <ul class="dropdown-menu" data-dropdown-target="menu" hidden></ul>
//   </div>
export default class extends Controller {
  static targets = ["select", "trigger", "label", "menu"]

  connect() {
    this.element.classList.add("dropdown--js")

    if (this.hasTriggerTarget) {
      this.triggerTarget.setAttribute("aria-haspopup", "listbox")
      this.triggerTarget.setAttribute("aria-expanded", "false")
    }

    this.buildMenu()
    this.syncLabel()

    this.onDocumentClick = this.onDocumentClick.bind(this)
    document.addEventListener("click", this.onDocumentClick)
  }

  disconnect() {
    this.element.classList.remove("dropdown--js")
    document.removeEventListener("click", this.onDocumentClick)
  }

  // Rebuild the custom <li> options from whatever is currently in
  // the <select>, so this keeps working if options are swapped in
  // dynamically (e.g. Turbo Stream updates).
  buildMenu() {
    if (!this.hasMenuTarget || !this.hasSelectTarget) return

    this.menuTarget.innerHTML = ""

    Array.from(this.selectTarget.options).forEach((option, index) => {
      const item = document.createElement("li")
      item.className = "dropdown-option"
      item.setAttribute("role", "option")
      item.dataset.value = option.value
      item.dataset.index = index
      item.textContent = option.text
      if (option.disabled) item.setAttribute("aria-disabled", "true")
      if (option.selected) item.classList.add("is-selected")
      item.addEventListener("click", () => this.selectOption(option, item))
      this.menuTarget.appendChild(item)
    })
  }

  toggle(event) {
    event.preventDefault()
    if (this.selectTarget.disabled) return
    this.isOpen ? this.close() : this.open()
  }

  open() {
    this.buildMenu()
    this.menuTarget.hidden = false
    this.element.classList.add("is-open")
    this.isOpen = true
    if (this.hasTriggerTarget) this.triggerTarget.setAttribute("aria-expanded", "true")

    const current = this.menuTarget.querySelector(".is-selected")
    if (current) current.scrollIntoView({ block: "nearest" })
  }

  close() {
    this.menuTarget.hidden = true
    this.element.classList.remove("is-open")
    this.isOpen = false
    if (this.hasTriggerTarget) this.triggerTarget.setAttribute("aria-expanded", "false")
  }

  selectOption(option, item) {
    if (option.disabled) return

    this.selectTarget.value = option.value
    this.selectTarget.dispatchEvent(new Event("change", { bubbles: true }))

    this.menuTarget.querySelectorAll(".dropdown-option").forEach((el) => el.classList.remove("is-selected"))
    item.classList.add("is-selected")

    this.syncLabel()
    this.close()
  }

  // Keep the visible label in sync if the underlying <select> value
  // changes from outside this controller (e.g. form reset, Turbo).
  syncLabel() {
    if (!this.hasLabelTarget || !this.hasSelectTarget) return
    const selected = this.selectTarget.options[this.selectTarget.selectedIndex]
    this.labelTarget.textContent = selected ? selected.text : ""
  }

  onDocumentClick(event) {
    if (this.isOpen && !this.element.contains(event.target)) {
      this.close()
    }
  }

  // Keyboard support on the trigger button.
  onKeydown(event) {
    switch (event.key) {
      case "Escape":
        this.close()
        break

      case "Enter":
      case " ":
        event.preventDefault()
        if (!this.isOpen) this.open()
        break

      case "ArrowDown":
        event.preventDefault()
        if (!this.isOpen) {
          this.open()
        } else {
          this.moveSelection(1)
        }
        break

      case "ArrowUp":
        event.preventDefault()
        if (!this.isOpen) {
          this.open()
        } else {
          this.moveSelection(-1)
        }
        break
    }
  }

  moveSelection(delta) {
    const options = Array.from(this.selectTarget.options)
    if (options.length === 0) return

    let index = this.selectTarget.selectedIndex + delta
    index = Math.max(0, Math.min(options.length - 1, index))

    const option = options[index]
    if (option.disabled) return

    const item = this.menuTarget.children[index]
    this.selectOption(option, item)
    this.open() // keep menu open while navigating with arrow keys
  }
}
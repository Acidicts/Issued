import { Controller } from "@hotwired/stimulus"

// Reveals and hides the ship-request popup. This used to be inline onclick attributes,
// but the app's Content-Security-Policy carries a script-src nonce without 'unsafe-inline'
// or 'unsafe-hashes', so browsers refuse to run inline event handlers.
//
// The controller sits on <body>: a Stimulus action only fires on the controller element or
// one of its descendants, and the trigger (the Ship link) is nowhere near the popup.
export default class extends Controller {
  static targets = ["popup"]

  open() {
    if (!this.hasPopupTarget) return

    this.popupTarget.classList.remove("hidden", "fadeToHide")
    this.popupTarget.classList.add("fadeToShow")
  }

  close() {
    if (!this.hasPopupTarget) return

    this.popupTarget.classList.remove("fadeToShow")
    this.popupTarget.classList.add("fadeToHide")
    this.popupTarget.addEventListener(
      "animationend",
      () => {
        this.popupTarget.classList.add("hidden")
      },
      { once: true }
    )
  }
}
import { Controller } from "@hotwired/stimulus"

// Proof videos are tens of megabytes, so a review submit can look like a dead
// button while the browser is still streaming the file. This surfaces what is
// happening in a status line next to the field.
//
// Deliberately never touches the submit buttons. Active Storage re-clicks the
// button once the direct upload finishes, so relabelling or disabling it here
// would replace the button's value -- the controller reads `status_set` to decide
// between Approve, Reject and Elevate -- and the review would come back as
// "no status selected". Active Storage's own `data-direct-uploads-processing`
// guard already stops a second submit while an upload is in flight.
export default class extends Controller {
  static targets = ["status"]

  connect() {
    this.uploading = false
  }

  submitted() {
    this.show("Uploading proof\u2026")
  }

  start() {
    this.uploading = true
    this.show("Uploading proof\u2026")
  }

  progress(event) {
    const percent = Math.round(event.detail.progress)
    if (percent > 0) this.show(`Uploading proof\u2026 ${percent}%`)
  }

  finish() {
    this.uploading = false
    this.clear()
  }

  failed(event) {
    this.uploading = false
    this.show("Upload failed, please pick the file and try again")
    event.preventDefault()
  }

  disconnect() {
    this.clear()
  }

  show(message) {
    if (this.hasStatusTarget) this.statusTarget.textContent = message
  }

  clear() {
    if (this.hasStatusTarget) this.statusTarget.textContent = ""
  }
}

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["designSelect", "designImage", "designOverlay", "emptyState", "productImage", "canvas"]

  connect() {
    this.scale = 1

    if (this.hasProductImageTarget) {
      if (this.productImageTarget.complete) {
        this.computeScale()
      } else {
        this.productImageTarget.addEventListener("load", () => this.computeScale())
      }
    }

    this.resizeHandler = () => this.computeScale()
    window.addEventListener("resize", this.resizeHandler)
  }

  disconnect() {
    window.removeEventListener("resize", this.resizeHandler)
  }

  computeScale() {
    const img = this.productImageTarget
    if (!img || !img.naturalWidth) return

    const canvas = this.canvasTarget
    const canvasRect = canvas.getBoundingClientRect()
    const imgRect = img.getBoundingClientRect()

    const displayedW = imgRect.width
    const displayedH = imgRect.height
    const naturalW = img.naturalWidth
    const naturalH = img.naturalHeight

    this.scale = Math.min(displayedW / naturalW, displayedH / naturalH)

    this.imgOffsetX = imgRect.left - canvasRect.left
    this.imgOffsetY = imgRect.top - canvasRect.top

    this.positionOverlay()
  }

  positionOverlay() {
    const canvas = this.canvasTarget
    const x = parseInt(canvas.dataset.imageX) || 0
    const y = parseInt(canvas.dataset.imageY) || 0
    const wx = parseInt(canvas.dataset.imageWx) || 0
    const wy = parseInt(canvas.dataset.imageWy) || 0

    const box = this.designOverlayTarget
    box.style.left = (this.imgOffsetX + x * this.scale) + "px"
    box.style.top = (this.imgOffsetY + y * this.scale) + "px"
    box.style.width = (wx * this.scale) + "px"
    box.style.height = (wy * this.scale) + "px"
  }

  updateDesign() {
    const selected = this.designSelectTarget.options[this.designSelectTarget.selectedIndex]
    const imageUrl = selected?.dataset?.imageUrl || ""

    if (!imageUrl) {
      this.designOverlayTarget.style.display = "none"
      this.emptyStateTarget.style.display = "flex"
      return
    }

    this.designImageTarget.src = imageUrl
    this.designOverlayTarget.style.display = "flex"
    this.emptyStateTarget.style.display = "none"
  }
}

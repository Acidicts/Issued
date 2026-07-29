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

    const imgAspect = naturalW / naturalH
    const boxAspect = displayedW / displayedH

    let renderedW, renderedH, renderedX, renderedY

    if (imgAspect >= boxAspect) {
      renderedW = displayedW
      renderedH = displayedW / imgAspect
    } else {
      renderedH = displayedH
      renderedW = displayedH * imgAspect
    }

    renderedX = (displayedW - renderedW) / 2
    renderedY = (displayedH - renderedH) / 2

    this.scale = renderedW / naturalW

    this.imgOffsetX = (imgRect.left - canvasRect.left) + renderedX
    this.imgOffsetY = (imgRect.top - canvasRect.top) + renderedY

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

    if (this.designImageTarget.complete) {
      this.positionOverlay()
    } else {
      this.designImageTarget.addEventListener("load", () => this.positionOverlay(), { once: true })
    }
  }
}

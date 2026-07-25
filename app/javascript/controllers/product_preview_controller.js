import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "canvas", "productImage", "designBox", "placeholder",
    "inputX", "inputY", "inputWx", "inputWy"
  ]
  static values = { imgUrl: String }

  connect() {
    this.dragging = false
    this.resizing = false
    this.resizeHandle = null
    this.scale = 1
    this.startX = 0
    this.startY = 0
    this.startBoxX = 0
    this.startBoxY = 0
    this.startBoxW = 0
    this.startBoxH = 0

    if (this.hasProductImageTarget) {
      this.productImageTarget.addEventListener("load", () => this.syncFromInputs())
    }

    if (this.imgUrlValue) {
      this.loadImage(this.imgUrlValue)
    } else {
      this.syncFromInputs()
    }
  }

  disconnect() {
    this.stopDrag()
  }

  // --- Image loading ---
  loadImage(url) {
    if (!url) return
    if (!this.hasProductImageTarget) {
      const img = document.createElement("img")
      img.className = "preview-product-img"
      img.alt = "Product preview"
      img.dataset.productPreviewTarget = "productImage"
      img.addEventListener("load", () => this.syncFromInputs())
      this.canvasTarget.innerHTML = ""
      this.canvasTarget.appendChild(img)
      this.canvasTarget.appendChild(this.designBoxTarget)
      this.productImageTarget = img
    }
    this.productImageTarget.src = url
    if (this.hasPlaceholderTarget) {
      this.placeholderTarget.style.display = "none"
    }
  }

  imageSelected(event) {
    const file = event.target.files[0]
    if (!file) return
    const reader = new FileReader()
    reader.onload = (e) => this.loadImage(e.target.result)
    reader.readAsDataURL(file)
  }

  // --- Sync from inputs to preview ---
  syncFromInputs() {
    if (!this.hasInputXTarget) return

    const x = parseInt(this.inputXTarget.value) || 0
    const y = parseInt(this.inputYTarget.value) || 0
    const wx = parseInt(this.inputWxTarget.value) || 0
    const wy = parseInt(this.inputWyTarget.value) || 0

    this.updateScale()

    const canvasRect = this.canvasTarget.getBoundingClientRect()
    const imgX = this.getImageOffsetX()
    const imgY = this.getImageOffsetY()

    const box = this.designBoxTarget
    box.style.left = (imgX + x * this.scale) + "px"
    box.style.top = (imgY + y * this.scale) + "px"
    box.style.width = (wx * this.scale) + "px"
    box.style.height = (wy * this.scale) + "px"
    box.style.display = (wx > 0 && wy > 0) ? "flex" : "none"
  }

  inputChanged() {
    this.syncFromInputs()
  }

  // --- Drag ---
  dragStart(event) {
    const box = this.designBoxTarget
    if (box.style.display === "none") return

    const boxRect = box.getBoundingClientRect()
    const canvasRect = this.canvasTarget.getBoundingClientRect()

    const clientX = event.clientX
    const clientY = event.clientY

    const onBox = clientX >= boxRect.left && clientX <= boxRect.right &&
                  clientY >= boxRect.top && clientY <= boxRect.bottom

    if (!onBox) return

    const handle = this.getResizeHandle(clientX, clientY, boxRect)

    if (handle) {
      this.resizing = true
      this.resizeHandle = handle
    } else {
      this.dragging = true
    }

    this.startX = clientX
    this.startY = clientY
    this.startBoxX = parseInt(this.inputXTarget.value) || 0
    this.startBoxY = parseInt(this.inputYTarget.value) || 0
    this.startBoxW = parseInt(this.inputWxTarget.value) || 0
    this.startBoxH = parseInt(this.inputWyTarget.value) || 0

    this.onDragMoveHandler = (e) => this.dragMove(e)
    this.onDragEndHandler = () => this.stopDrag()
    document.addEventListener("mousemove", this.onDragMoveHandler)
    document.addEventListener("mouseup", this.onDragEndHandler)
    event.preventDefault()
  }

  dragMove(event) {
    const dx = (event.clientX - this.startX) / this.scale
    const dy = (event.clientY - this.startY) / this.scale

    if (this.dragging) {
      const newX = Math.max(0, Math.round(this.startBoxX + dx))
      const newY = Math.max(0, Math.round(this.startBoxY + dy))
      this.inputXTarget.value = newX
      this.inputYTarget.value = newY
    } else if (this.resizing) {
      this.applyResize(dx, dy)
    }

    this.syncFromInputs()
  }

  stopDrag() {
    this.dragging = false
    this.resizing = false
    this.resizeHandle = null
    document.removeEventListener("mousemove", this.onDragMoveHandler)
    document.removeEventListener("mouseup", this.onDragEndHandler)
  }

  // --- Resize ---
  getResizeHandle(cx, cy, rect) {
    const zone = 10
    const nearLeft = cx - rect.left <= zone
    const nearRight = rect.right - cx <= zone
    const nearTop = cy - rect.top <= zone
    const nearBottom = rect.bottom - cy <= zone

    if (nearRight && nearBottom) return "se"
    if (nearRight && nearTop) return "ne"
    if (nearLeft && nearBottom) return "sw"
    if (nearLeft && nearTop) return "nw"
    if (nearRight) return "e"
    if (nearLeft) return "w"
    if (nearBottom) return "s"
    if (nearTop) return "n"
    return null
  }

  applyResize(dx, dy) {
    let x = this.startBoxX
    let y = this.startBoxY
    let w = this.startBoxW
    let h = this.startBoxH
    const handle = this.resizeHandle

    if (handle.includes("e")) w = Math.max(10, Math.round(w + dx))
    if (handle.includes("w")) { x = Math.round(x + dx); w = Math.max(10, Math.round(w - dx)) }
    if (handle.includes("s")) h = Math.max(10, Math.round(h + dy))
    if (handle.includes("n")) { y = Math.round(y + dy); h = Math.max(10, Math.round(h - dy)) }

    if (x < 0) { w += x; x = 0 }
    if (y < 0) { h += y; y = 0 }

    this.inputXTarget.value = x
    this.inputYTarget.value = y
    this.inputWxTarget.value = w
    this.inputWyTarget.value = h
  }

  // --- Helpers ---
  updateScale() {
    if (!this.hasProductImageTarget || !this.productImageTarget.naturalWidth) {
      this.scale = 1
      return
    }
    const displayedW = this.productImageTarget.getBoundingClientRect().width
    this.scale = displayedW / this.productImageTarget.naturalWidth
  }

  getImageOffsetX() {
    if (!this.hasProductImageTarget) return 0
    const canvasRect = this.canvasTarget.getBoundingClientRect()
    const imgRect = this.productImageTarget.getBoundingClientRect()
    return imgRect.left - canvasRect.left
  }

  getImageOffsetY() {
    if (!this.hasProductImageTarget) return 0
    const canvasRect = this.canvasTarget.getBoundingClientRect()
    const imgRect = this.productImageTarget.getBoundingClientRect()
    return imgRect.top - canvasRect.top
  }
}

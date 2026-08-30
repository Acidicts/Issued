import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "designSelect", "designImage", "designImgWrap", "printArea", "emptyState",
    "productImage", "canvas",
    "inputX", "inputY", "inputWx", "inputWy", "inputRotation"
  ]
  static values = {
    imageX: Number,
    imageY: Number,
    imageWx: Number,
    imageWy: Number,
    colorHex: String
  }

  connect() {
    this.scale = 1
    this.imgOffsetX = 0
    this.imgOffsetY = 0
    this.dragging = false
    this.resizing = false
    this.rotating = false
    this.resizeDir = null
    this.startX = 0
    this.startY = 0
    this.startBoxX = 0
    this.startBoxY = 0
    this.startBoxW = 0
    this.startBoxH = 0
    this.startRotation = 0

    const queryString = window.location.search;
    const urlParams = new URLSearchParams(queryString);

    if (this.hasProductImageTarget) {
      this.productImageTarget.addEventListener("load", () => this.computeScale())
    }

    this.computeScale()

    this.resizeHandler = () => this.computeScale()
    window.addEventListener("resize", this.resizeHandler)

    if (urlParams.has("design_id")) {
      this.updateDesign();
    } else if (this.designSelectTarget.value) {
      this.updateDesign();
    }
    this.updateColor();
  }

  disconnect() {
    window.removeEventListener("resize", this.resizeHandler)
    this.stopDrag()
  }

  flashClamp() {
    if (!this.hasPrintAreaTarget) return
    const pa = this.printAreaTarget
    pa.style.boxShadow = "0 0 0 9999px rgba(0, 0, 0, 0.4)"
    clearTimeout(this._clampFlashTimer)
    this._clampFlashTimer = setTimeout(() => { pa.style.boxShadow = "" }, 200)
  }

  rotatedAabb(w, h, deg) {
    const rad = (deg * Math.PI) / 180
    const cos = Math.abs(Math.cos(rad))
    const sin = Math.abs(Math.sin(rad))
    return { w: Math.round(w * cos + h * sin), h: Math.round(w * sin + h * cos) }
  }

  maxDimensions(w, h, rotation) {
    const s = w / h
    const rad = (rotation * Math.PI) / 180
    const cos = Math.abs(Math.cos(rad))
    const sin = Math.abs(Math.sin(rad))
    const maxH = Math.min(this.imageWxValue / (s * cos + sin), this.imageWyValue / (s * sin + cos))
    let mh = Math.min(h, Math.floor(maxH))
    let mw = Math.round(mh * s)
    if (mw > w) { mw = w; mh = Math.round(mw / s) }
    if (mh > maxH) { mh = Math.floor(maxH); mw = Math.round(mh * s) }
    return { w: Math.max(10, mw), h: Math.max(10, mh) }
  }

  clampPosition(x, y, w, h, rotation) {
    const wrap = this.designImgWrapTarget
    const canvas = this.canvasTarget
    if (!wrap || !canvas || w <= 0 || h <= 0) {
      const aabb = this.rotatedAabb(w, h, rotation)
      const cx = Math.max(this.imageXValue, Math.min(Math.round(x), this.imageXValue + this.imageWxValue - aabb.w))
      const cy = Math.max(this.imageYValue, Math.min(Math.round(y), this.imageYValue + this.imageWyValue - aabb.h))
      return { x: cx, y: cy, clamped: cx !== Math.round(x) || cy !== Math.round(y) }
    }

    const canvasRect = canvas.getBoundingClientRect()

    const wasHidden = wrap.style.display === "none"
    if (wasHidden) {
      wrap.style.visibility = "hidden"
      wrap.style.display = "flex"
    }

    wrap.style.left = (this.imgOffsetX + x * this.scale) + "px"
    wrap.style.top = (this.imgOffsetY + y * this.scale) + "px"
    wrap.style.width = (w * this.scale) + "px"
    wrap.style.height = (h * this.scale) + "px"
    wrap.style.transform = `rotate(${rotation}deg)`

    const wrapRect = wrap.getBoundingClientRect()

    if (wasHidden) {
      wrap.style.display = "none"
      wrap.style.visibility = ""
    }

    const bbLeft = (wrapRect.left - canvasRect.left - this.imgOffsetX) / this.scale
    const bbTop = (wrapRect.top - canvasRect.top - this.imgOffsetY) / this.scale
    const bbW = wrapRect.width / this.scale
    const bbH = wrapRect.height / this.scale

    const paL = this.imageXValue
    const paT = this.imageYValue
    const paR = this.imageXValue + this.imageWxValue
    const paB = this.imageYValue + this.imageWyValue

    let shiftX = 0
    let shiftY = 0
    if (bbLeft < paL) shiftX = paL - bbLeft
    else if (bbLeft + bbW > paR) shiftX = paR - bbLeft - bbW
    if (bbTop < paT) shiftY = paT - bbTop
    else if (bbTop + bbH > paB) shiftY = paB - bbTop - bbH

    return { x: Math.round(x + shiftX), y: Math.round(y + shiftY), clamped: shiftX !== 0 || shiftY !== 0 }
  }

  computeScale() {
    if (!this.hasProductImageTarget) {
      this.scale = 1
      this.imgOffsetX = 0
      this.imgOffsetY = 0
      this.positionPrintArea()
      this.positionDesign()
      return
    }

    const img = this.productImageTarget
    if (!img.naturalWidth) {
      this.scale = 1
      this.imgOffsetX = 0
      this.imgOffsetY = 0
      this.positionPrintArea()
      this.positionDesign()
      return
    }

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

    this.positionPrintArea()
    this.positionDesign()
  }

  positionPrintArea() {
    if (!this.hasPrintAreaTarget) return

    const box = this.printAreaTarget
    const wx = this.imageWxValue
    const wy = this.imageWyValue

    box.style.left = (this.imgOffsetX + this.imageXValue * this.scale) + "px"
    box.style.top = (this.imgOffsetY + this.imageYValue * this.scale) + "px"
    box.style.width = (wx * this.scale) + "px"
    box.style.height = (wy * this.scale) + "px"
    box.style.display = (wx > 0 && wy > 0) ? "block" : "none"
  }

  positionDesign() {
    if (!this.hasDesignImgWrapTarget) return

    const hasImage = this.hasDesignImageTarget && this.designImageTarget.src && this.designImageTarget.src !== window.location.href
    const x = this.hasInputXTarget ? (parseInt(this.inputXTarget.value) || 0) : 0
    const y = this.hasInputYTarget ? (parseInt(this.inputYTarget.value) || 0) : 0
    const wx = this.hasInputWxTarget ? (parseInt(this.inputWxTarget.value) || 0) : 0
    const wy = this.hasInputWyTarget ? (parseInt(this.inputWyTarget.value) || 0) : 0
    const rotation = this.hasInputRotationTarget ? (parseInt(this.inputRotationTarget.value) || 0) : 0

    const wrap = this.designImgWrapTarget
    wrap.style.left = (this.imgOffsetX + x * this.scale) + "px"
    wrap.style.top = (this.imgOffsetY + y * this.scale) + "px"
    wrap.style.width = (wx * this.scale) + "px"
    wrap.style.height = (wy * this.scale) + "px"
    wrap.style.transform = `rotate(${rotation}deg)`
    wrap.style.display = (hasImage && wx > 0 && wy > 0) ? "flex" : "none"
  }

  inputChanged() {
    const x = parseInt(this.inputXTarget?.value) || 0
    const y = parseInt(this.inputYTarget?.value) || 0
    const wx = parseInt(this.inputWxTarget?.value) || 0
    const wy = parseInt(this.inputWyTarget?.value) || 0
    const rotation = parseInt(this.inputRotationTarget?.value) || 0

    if (wx > 0 && wy > 0) {
      const clamped = this.clampPosition(x, y, wx, wy, rotation)
      if (clamped.clamped) this.flashClamp()
      if (this.hasInputXTarget) this.inputXTarget.value = clamped.x
      if (this.hasInputYTarget) this.inputYTarget.value = clamped.y
    }

    this.positionDesign()
  }

  updateColor() {
    this.productImageTarget.style.backgroundColor = this.colorHexValues
  }

  updateDesign() {
    const selected = this.designSelectTarget.options[this.designSelectTarget.selectedIndex]
    const imageUrl = selected?.dataset?.imageUrl || ""

    if (!imageUrl) {
      this.designImageTarget.src = ""
      this.designImgWrapTarget.style.display = "none"
      this.emptyStateTarget.style.display = "flex"
      if (this.hasInputXTarget) this.inputXTarget.value = ""
      if (this.hasInputYTarget) this.inputYTarget.value = ""
      if (this.hasInputWxTarget) this.inputWxTarget.value = ""
      if (this.hasInputWyTarget) this.inputWyTarget.value = ""
      if (this.hasInputRotationTarget) this.inputRotationTarget.value = ""
      return
    }

    this.designImageTarget.src = imageUrl
    this.emptyStateTarget.style.display = "none"

    const hasExistingValues = (parseInt(this.inputXTarget?.value) || 0) > 0 ||
                              (parseInt(this.inputWxTarget?.value) || 0) > 0

    const positionFromInputs = () => {
      this.computeScale()
      this.positionDesign()
    }

    const fitAndPlace = () => {
      const rotation = parseInt(this.inputRotationTarget?.value) || 0
      const nw = this.designImageTarget.naturalWidth
      const nh = this.designImageTarget.naturalHeight
      const ratio = nw > 0 && nh > 0 ? nw / nh : 1

      let dw = this.imageWxValue
      let dh = Math.round(dw / ratio)
      if (dh > this.imageWyValue) {
        dh = this.imageWyValue
        dw = Math.round(dh * ratio)
      }

      const aabb = this.rotatedAabb(dw, dh, rotation)
      const dx = this.imageXValue + Math.round((this.imageWxValue - aabb.w) / 2)
      const dy = this.imageYValue + Math.round((this.imageWyValue - aabb.h) / 2)
      const clamped = this.clampPosition(dx, dy, dw, dh, rotation)

      this.inputXTarget.value = clamped.x
      this.inputYTarget.value = clamped.y
      this.inputWxTarget.value = dw
      this.inputWyTarget.value = dh
      this.inputRotationTarget.value = 0

      this.positionDesign()
    }

    if (hasExistingValues) {
      if (this.designImageTarget.complete && this.designImageTarget.naturalWidth) {
        positionFromInputs()
      } else {
        this.designImageTarget.onload = positionFromInputs
        this.designImageTarget.onerror = positionFromInputs
      }
    } else {
      if (this.designImageTarget.complete && this.designImageTarget.naturalWidth) {
        fitAndPlace()
      } else {
        this.designImageTarget.onload = fitAndPlace
        this.designImageTarget.onerror = fitAndPlace
      }
    }
  }

  dragStart(event) {
    const clientX = event.clientX
    const clientY = event.clientY

    const rotateHandle = this.designImgWrapTarget?.querySelector(".rotate-handle")
    if (rotateHandle) {
      const rhRect = rotateHandle.getBoundingClientRect()
      const zone = 10
      if (clientX >= rhRect.left - zone && clientX <= rhRect.right + zone &&
          clientY >= rhRect.top - zone && clientY <= rhRect.bottom + zone) {
        this.rotating = true
        this.startX = clientX
        this.startY = clientY
        this.startRotation = parseInt(this.inputRotationTarget?.value) || 0
        this.startDragListeners()
        event.preventDefault()
        return
      }
    }

    const resizeHandle = event.target.closest(".resize-handle")
    if (resizeHandle) {
      this.resizing = true
      this.resizeDir = resizeHandle.dataset.dir
      this.startX = clientX
      this.startY = clientY
      this.startBoxX = parseInt(this.inputXTarget.value) || 0
      this.startBoxY = parseInt(this.inputYTarget.value) || 0
      this.startBoxW = parseInt(this.inputWxTarget.value) || 0
      this.startBoxH = parseInt(this.inputWyTarget.value) || 0
      this.startDragListeners()
      event.preventDefault()
      return
    }

    const wrap = this.designImgWrapTarget
    if (!wrap || wrap.style.display === "none") return

    const wrapRect = wrap.getBoundingClientRect()
    const onWrap = clientX >= wrapRect.left && clientX <= wrapRect.right &&
                   clientY >= wrapRect.top && clientY <= wrapRect.bottom

    if (!onWrap) return

    this.dragging = true
    this.startX = clientX
    this.startY = clientY
    this.startBoxX = parseInt(this.inputXTarget.value) || 0
    this.startBoxY = parseInt(this.inputYTarget.value) || 0
    this.startDragListeners()
    event.preventDefault()
  }

  startDragListeners() {
    this.onDragMoveHandler = (e) => this.dragMove(e)
    this.onDragEndHandler = () => this.stopDrag()
    document.addEventListener("mousemove", this.onDragMoveHandler)
    document.addEventListener("mouseup", this.onDragEndHandler)
  }

  dragMove(event) {
    const dx = (event.clientX - this.startX) / this.scale
    const dy = (event.clientY - this.startY) / this.scale

    if (this.dragging) {
      const wx = parseInt(this.inputWxTarget.value) || 0
      const wy = parseInt(this.inputWyTarget.value) || 0
      const rotation = parseInt(this.inputRotationTarget.value) || 0

      const clamped = this.clampPosition(this.startBoxX + dx, this.startBoxY + dy, wx, wy, rotation)
      if (clamped.clamped) this.flashClamp()
      this.inputXTarget.value = clamped.x
      this.inputYTarget.value = clamped.y
    } else if (this.resizing) {
      this.applyResize(dx, dy)
    } else if (this.rotating) {
      this.applyRotation(event)
    }

    this.positionDesign()
  }

  stopDrag() {
    this.dragging = false
    this.resizing = false
    this.rotating = false
    this.resizeDir = null
    document.removeEventListener("mousemove", this.onDragMoveHandler)
    document.removeEventListener("mouseup", this.onDragEndHandler)
  }

  applyResize(dx, dy) {
    const dir = this.resizeDir
    const s = this.startBoxW / this.startBoxH
    const rotation = parseInt(this.inputRotationTarget?.value) || 0
    let w, h, x, y

    if (dir === "e") {
      w = Math.max(10, Math.round(this.startBoxW + dx))
      h = Math.round(w / s)
      const max = this.maxDimensions(w, h, rotation)
      w = max.w; h = max.h
      x = this.startBoxX
      y = this.startBoxY + Math.round((this.startBoxH - h) / 2)
    } else if (dir === "w") {
      w = Math.max(10, Math.round(this.startBoxW - dx))
      h = Math.round(w / s)
      const max = this.maxDimensions(w, h, rotation)
      w = max.w; h = max.h
      x = Math.round(this.startBoxX + (this.startBoxW - w))
      y = this.startBoxY + Math.round((this.startBoxH - h) / 2)
    } else if (dir === "s") {
      h = Math.max(10, Math.round(this.startBoxH + dy))
      w = Math.round(h * s)
      const max = this.maxDimensions(w, h, rotation)
      w = max.w; h = max.h
      x = this.startBoxX + Math.round((this.startBoxW - w) / 2)
      y = this.startBoxY
    } else if (dir === "n") {
      h = Math.max(10, Math.round(this.startBoxH - dy))
      w = Math.round(h * s)
      const max = this.maxDimensions(w, h, rotation)
      w = max.w; h = max.h
      x = this.startBoxX + Math.round((this.startBoxW - w) / 2)
      y = Math.round(this.startBoxY + (this.startBoxH - h))
    }

    const clamped = this.clampPosition(x, y, w, h, rotation)
    if (clamped.clamped) this.flashClamp()

    this.inputXTarget.value = clamped.x
    this.inputYTarget.value = clamped.y
    this.inputWxTarget.value = w
    this.inputWyTarget.value = h
  }

  applyRotation(event) {
    const wrap = this.designImgWrapTarget
    const rect = wrap.getBoundingClientRect()
    const centerX = rect.left + rect.width / 2
    const centerY = rect.top + rect.height / 2

    const startAngle = Math.atan2(this.startY - centerY, this.startX - centerX)
    const currentAngle = Math.atan2(event.clientY - centerY, event.clientX - centerX)

    let deltaDeg = ((currentAngle - startAngle) * 180) / Math.PI
    let newRotation = Math.round(this.startRotation + deltaDeg)
    newRotation = ((newRotation % 360) + 360) % 360

    this.inputRotationTarget.value = newRotation

    const wx = parseInt(this.inputWxTarget.value) || 0
    const wy = parseInt(this.inputWyTarget.value) || 0
    const max = this.maxDimensions(wx, wy, newRotation)
    this.inputWxTarget.value = max.w
    this.inputWyTarget.value = max.h

    const x = parseInt(this.inputXTarget.value) || 0
    const y = parseInt(this.inputYTarget.value) || 0
    const clamped = this.clampPosition(x, y, max.w, max.h, newRotation)
    if (clamped.clamped) this.flashClamp()
    this.inputXTarget.value = clamped.x
    this.inputYTarget.value = clamped.y
  }
}

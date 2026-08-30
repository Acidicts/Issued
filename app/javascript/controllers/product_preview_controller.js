import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "canvas", "productImage", "designBox", "placeholder",
    "inputX", "inputY", "inputWx", "inputWy",
    "printAreaSelect", "printAreaName", "printAreaId", "printAreasJson",
    "templateImage", "templateImageInput", "templateImageUrl"
  ]
  static values = {
    imgUrl: String,
    printAreas: Array,
    nextTempId: Number
  }

  connect() {
    this.dragging = false
    this.resizing = false
    this.resizeHandle = null
    this.scale = 1
    this.renderedOffsetX = 0
    this.renderedOffsetY = 0
    this.startX = 0
    this.startY = 0
    this.startBoxX = 0
    this.startBoxY = 0
    this.startBoxW = 0
    this.startBoxH = 0
    this.activeIndex = null

    this.nextTempIdValue = this.printAreasValue.length > 0
      ? Math.max(...this.printAreasValue.map(p => p.id || 0)) + 1
      : 1

    this.rebuildSelect()

    if (this.hasPrintAreaSelectTarget && this.printAreasValue.length > 0) {
      this.printAreaSelectTarget.selectedIndex = 1
      this.loadPrintArea(0)
    }

    if (this.hasProductImageTarget) {
      this.productImageTarget.addEventListener("load", () => this.syncFromInputs())
    }

    if (this.imgUrlValue) {
      this.loadImage(this.imgUrlValue)
    } else {
      this.syncFromInputs()
    }

    this.syncTemplateImage()
  }

  disconnect() {
    this.stopDrag()
  }

  // --- Print area switching ---

  printAreaChanged() {
    const idx = this.printAreaSelectTarget.selectedIndex - 1
    if (idx >= 0) {
      this.loadPrintArea(idx)
    } else {
      this.clearPrintAreaFields()
    }
  }

  loadPrintArea(index) {
    const pa = this.printAreasValue[index]
    if (!pa) return

    this.activeIndex = index
    this.printAreaNameTarget.value = pa.name || ""
    this.inputXTarget.value = pa.image_x
    this.inputYTarget.value = pa.image_y
    this.inputWxTarget.value = pa.image_wx
    this.inputWyTarget.value = pa.image_wy

    if (this.hasTemplateImageUrlTarget) {
      this.templateImageUrlTarget.value = pa.template_image_url || ""
    }

    this.syncTemplateImage()
    this.syncFromInputs()
  }

  clearPrintAreaFields() {
    this.activeIndex = null
    this.printAreaNameTarget.value = ""
    this.inputXTarget.value = ""
    this.inputYTarget.value = ""
    this.inputWxTarget.value = ""
    this.inputWyTarget.value = ""

    if (this.hasTemplateImageUrlTarget) this.templateImageUrlTarget.value = ""
    if (this.hasTemplateImageInputTarget) this.templateImageInputTarget.value = ""

    const box = this.getDesignBox()
    if (box) box.style.display = "none"

    this.syncTemplateImage()
    this.syncTemplateImagePosition()
  }

  addPrintArea() {
    this.syncActivePrintArea()

    const name = "Print Area " + (this.printAreasValue.length + 1)
    const newPA = {
      id: null,
      name: name,
      image_x: 0,
      image_y: 0,
      image_wx: 200,
      image_wy: 200,
      template_image_url: "",
      _destroy: false
    }

    this.printAreasValue.push(newPA)
    this.rebuildSelect()

    const newIndex = this.printAreasValue.length - 1
    this.printAreaSelectTarget.selectedIndex = newIndex + 1
    this.loadPrintArea(newIndex)
  }

  removePrintArea() {
    if (this.activeIndex === null) return

    const pa = this.printAreasValue[this.activeIndex]
    const displayName = pa.name || "this print area"
    if (!confirm(`Remove "${displayName}"?`)) return

    if (pa.id) {
      pa._destroy = true
    } else {
      this.printAreasValue.splice(this.activeIndex, 1)
    }

    this.rebuildSelect()

    if (this.printAreasValue.some(p => !p._destroy)) {
      const nextIdx = this.findNextVisibleIndex(this.activeIndex)
      if (nextIdx !== null) {
        this.printAreaSelectTarget.selectedIndex = nextIdx + 1
        this.loadPrintArea(nextIdx)
      } else {
        this.printAreaSelectTarget.selectedIndex = 0
        this.clearPrintAreaFields()
      }
    } else {
      this.printAreaSelectTarget.selectedIndex = 0
      this.clearPrintAreaFields()
    }
  }

  findNextVisibleIndex(fromIndex) {
    for (let i = fromIndex + 1; i < this.printAreasValue.length; i++) {
      if (!this.printAreasValue[i]._destroy) return i
    }
    for (let i = fromIndex - 1; i >= 0; i--) {
      if (!this.printAreasValue[i]._destroy) return i
    }
    return null
  }

  rebuildSelect() {
    const select = this.printAreaSelectTarget
    const prevValue = select.value

    while (select.options.length > 1) select.remove(1)

    this.printAreasValue.forEach((pa, i) => {
      if (pa._destroy) return
      const opt = document.createElement("option")
      opt.value = i
      opt.textContent = pa.name || ("Print Area " + (i + 1))
      select.appendChild(opt)
    })

    if (prevValue && select.querySelector(`option[value="${prevValue}"]`)) {
      select.value = prevValue
    }
  }

  // --- Template image upload ---

  templateImageFileChanged(event) {
    const file = event.target.files[0]
    if (!file || this.activeIndex === null) return

    const pa = this.printAreasValue[this.activeIndex]
    pa._pendingTemplateFile = file.name

    const reader = new FileReader()
    reader.onload = (e) => {
      pa.template_image_url = e.target.result
      this.syncTemplateImage()
    }
    reader.readAsDataURL(file)
  }

  // --- Sync on submit ---

  syncBeforeSubmit() {
    this.syncActivePrintArea()
  }

  syncActivePrintArea() {
    if (this.activeIndex === null) return

    const pa = this.printAreasValue[this.activeIndex]
    if (!pa) return

    pa.name = this.printAreaNameTarget.value
    pa.image_x = parseInt(this.inputXTarget.value) || 0
    pa.image_y = parseInt(this.inputYTarget.value) || 0
    pa.image_wx = parseInt(this.inputWxTarget.value) || 0
    pa.image_wy = parseInt(this.inputWyTarget.value) || 0

    if (this.hasTemplateImageUrlTarget) {
      pa.template_image_url = this.templateImageUrlTarget.value
    }

    this.syncPrintAreasJson()
  }

  syncPrintAreasJson() {
    if (!this.hasPrintAreasJsonTarget) return
    this.printAreasJsonTarget.value = JSON.stringify(this.printAreasValue)
  }

  syncTemplateImage() {
    if (!this.hasTemplateImageTarget) return

    if (this.activeIndex === null) {
      this.templateImageTarget.style.display = "none"
      this.templateImageTarget.src = ""
      this.syncTemplateImagePosition()
      return
    }

    const pa = this.printAreasValue[this.activeIndex]
    if (!pa || !pa.template_image_url) {
      this.templateImageTarget.style.display = "none"
      this.templateImageTarget.src = ""
      this.syncTemplateImagePosition()
      return
    }

    this.templateImageTarget.src = pa.template_image_url
    this.templateImageTarget.style.display = "block"
    this.syncTemplateImagePosition()
  }

  // --- Image loading ---

  loadImage(url) {
    if (!url) return

    const canvas = this.canvasTarget
    let img = canvas.querySelector('img.preview-product-img')

    if (!img) {
      const designBox = this.getDesignBox()
      const placeholder = this.hasPlaceholderTarget ? this.placeholderTarget : null

      canvas.innerHTML = ""

      img = document.createElement("img")
      img.className = "preview-product-img"
      img.alt = "Product preview"
      img.dataset.productPreviewTarget = "productImage"
      img.addEventListener("load", () => {
        this.syncFromInputs()
        this.syncTemplateImagePosition()
      })
      canvas.appendChild(img)

      if (this.hasTemplateImageTarget) canvas.appendChild(this.templateImageTarget)
      if (designBox) canvas.appendChild(designBox)
      if (placeholder) placeholder.style.display = "none"
    }

    img.src = url
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

    const imgX = this.getImageOffsetX()
    const imgY = this.getImageOffsetY()

    const box = this.getDesignBox()
    if (!box) return

    box.style.left = (imgX + x * this.scale) + "px"
    box.style.top = (imgY + y * this.scale) + "px"
    box.style.width = (wx * this.scale) + "px"
    box.style.height = (wy * this.scale) + "px"
    box.style.display = (wx > 0 && wy > 0) ? "flex" : "none"

    this.syncTemplateImagePosition()
  }

  syncTemplateImagePosition() {
    if (!this.hasTemplateImageTarget) return

    if (this.templateImageTarget.style.display === "none") {
      if (this.hasProductImageTarget) this.productImageTarget.style.display = ""
      return
    }

    if (!this.hasProductImageTarget) return

    const productImg = this.productImageTarget
    const imgRect = productImg.getBoundingClientRect()
    if (imgRect.width === 0 || imgRect.height === 0) return

    this.templateImageTarget.style.position = "absolute"
    this.templateImageTarget.style.left = "0"
    this.templateImageTarget.style.top = "0"
    this.templateImageTarget.style.width = imgRect.width + "px"
    this.templateImageTarget.style.height = imgRect.height + "px"
    this.templateImageTarget.style.objectFit = "contain"
    this.templateImageTarget.style.pointerEvents = "none"
    this.templateImageTarget.style.zIndex = "2"

    productImg.style.display = "none"
  }

  inputChanged() {
    this.syncFromInputs()
  }

  // --- Drag ---

  dragStart(event) {
    const box = this.getDesignBox()
    if (!box || box.style.display === "none") return

    const boxRect = box.getBoundingClientRect()
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

  getDesignBox() {
    return this.hasDesignBoxTarget
      ? this.designBoxTarget
      : this.canvasTarget.querySelector('[data-product-preview-target="designBox"]')
  }

  updateScale() {
    const img = this.getDisplayImage()
    if (!img || !img.naturalWidth) {
      this.scale = 1
      this.renderedOffsetX = 0
      this.renderedOffsetY = 0
      return
    }

    const imgRect = img.getBoundingClientRect()
    const displayedW = imgRect.width
    const displayedH = imgRect.height
    const naturalW = img.naturalWidth
    const naturalH = img.naturalHeight

    if (displayedW === 0 || displayedH === 0) {
      this.scale = 1
      this.renderedOffsetX = 0
      this.renderedOffsetY = 0
      return
    }

    const imgAspect = naturalW / naturalH
    const boxAspect = displayedW / displayedH

    let renderedW, renderedH
    if (imgAspect >= boxAspect) {
      renderedW = displayedW
      renderedH = displayedW / imgAspect
    } else {
      renderedH = displayedH
      renderedW = displayedH * imgAspect
    }

    this.scale = renderedW / naturalW
    this.renderedOffsetX = (displayedW - renderedW) / 2
    this.renderedOffsetY = (displayedH - renderedH) / 2
  }

  getDisplayImage() {
    if (this.hasProductImageTarget && this.productImageTarget.style.display !== "none") {
      return this.productImageTarget
    }
    if (this.hasTemplateImageTarget && this.templateImageTarget.style.display !== "none") {
      return this.templateImageTarget
    }
    return this.hasProductImageTarget ? this.productImageTarget : null
  }

  getImageOffsetX() {
    const img = this.getDisplayImage()
    if (!img) return 0
    const canvasRect = this.canvasTarget.getBoundingClientRect()
    const imgRect = img.getBoundingClientRect()
    return (imgRect.left - canvasRect.left) + (this.renderedOffsetX || 0)
  }

  getImageOffsetY() {
    const img = this.getDisplayImage()
    if (!img) return 0
    const canvasRect = this.canvasTarget.getBoundingClientRect()
    const imgRect = img.getBoundingClientRect()
    return (imgRect.top - canvasRect.top) + (this.renderedOffsetY || 0)
  }
}

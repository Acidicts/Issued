import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.maxWidth = 0
    this.maxHeight = 0

    this.observer = new ResizeObserver((entries) => {
      for (const entry of entries) {
        const { width, height } = entry.contentRect
        if (width > this.maxWidth) {
          this.maxWidth = width
          this.element.style.minWidth = `${width}px`
        }
        if (height > this.maxHeight) {
          this.maxHeight = height
          this.element.style.minHeight = `${height}px`
        }
      }
    })

    this.observer.observe(this.element)
  }

  disconnect() {
    this.observer?.disconnect()
  }
}

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["code", "preview", "svgCode", "elapsedSeconds", "timer", "validation", "name", "description", "saveState", "rootOpen", "rootClose"]
  static values = {
    storageKey: String,
    autosaveUrl: String,
    persisted: Boolean
  }

  connect() {
    this.history = []
    this.future = []
    this.hasUpdates = false
    this.forceDarkMode = false
    this.recordedSeconds = Number(this.elapsedSecondsTarget?.value || 0)
    this.initialSeconds = this.recordedSeconds
    this.updateTimerDisplay()

    const initialSvg = this.svgCodeTarget?.value || this.codeTarget?.value || this.defaultSvg()
    const initialParts = this.splitSvg(initialSvg)
    this.rootOpenTag = initialParts.rootOpenTag
    this.rootCloseTag = "</svg>"
    this.codeTarget.value = initialParts.innerContent
    this.updateRootLockLines()
    this.syncHiddenCode()

    this.restoreDraft()

    this.updatePreview(false)
    this.interval = setInterval(() => this.tick(), 1000)
    this.draftInterval = setInterval(() => this.persistDraft(false), 6000)

    this.beforeUnloadHandler = () => this.flushBeforeLeave()
    this.pageHideHandler = () => this.flushBeforeLeave()
    this.visibilityHandler = () => {
      if (document.visibilityState === "hidden") this.flushBeforeLeave()
    }

    window.addEventListener("beforeunload", this.beforeUnloadHandler)
    window.addEventListener("pagehide", this.pageHideHandler)
    document.addEventListener("visibilitychange", this.visibilityHandler)

    this.updateSaveState("Draft protection active")
  }

  disconnect() {
    clearInterval(this.interval)
    clearInterval(this.draftInterval)
    window.removeEventListener("beforeunload", this.beforeUnloadHandler)
    window.removeEventListener("pagehide", this.pageHideHandler)
    document.removeEventListener("visibilitychange", this.visibilityHandler)
    this.persistDraft(false)
  }

  tick() {
    this.recordedSeconds += 1
    this.elapsedSecondsTarget.value = this.recordedSeconds
    this.updateTimerDisplay()

    if (this.recordedSeconds % 10 === 0) this.persistDraft(false)
  }

  updateTimerDisplay() {
    const seconds = this.recordedSeconds
    const h = String(Math.floor(seconds / 3600)).padStart(2, "0")
    const m = String(Math.floor((seconds % 3600) / 60)).padStart(2, "0")
    const s = String(seconds % 60).padStart(2, "0")
    this.timerTarget.textContent = `${h}:${m}:${s}`
  }

  updatePreview(trigger = true) {
    const shouldMarkDirty = trigger !== false
    const code = this.normalizeEditableCode(this.codeTarget.value)
    if (code !== this.codeTarget.value) {
      this.codeTarget.value = code
    }

    const wrappedCode = this.wrapWithRoot(code)
    this.syncHiddenCode()
    this.pushHistory(code)

    const previewRoot = this.previewTarget
    previewRoot.innerHTML = ""

    try {
      const parser = new DOMParser()
      const doc = parser.parseFromString(wrappedCode, "image/svg+xml")
      const svg = doc.querySelector("svg")

      if (!svg) throw new Error("SVG document must contain a <svg> root element")

      this.validationTarget.textContent = "No errors"
      this.validationTarget.style.color = "#20a860"

      const clone = svg.cloneNode(true)
      clone.setAttribute("width", "100%")
      clone.setAttribute("height", "100%")
      clone.style.maxWidth = "100%"
      clone.style.maxHeight = "100%"
      clone.style.display = "block"
      clone.style.boxSizing = "border-box"

      previewRoot.appendChild(clone)
    } catch (error) {
      this.validationTarget.textContent = "Error: " + error.message
      this.validationTarget.style.color = "#d13f44"
      const errMsg = document.createElement("pre")
      errMsg.textContent = error.stack || error.message
      errMsg.style.color = "#d13f44"
      errMsg.style.whiteSpace = "pre-wrap"
      errMsg.style.margin = "0"
      previewRoot.appendChild(errMsg)
    }

    if (shouldMarkDirty) {
      this.markDirty()
    }

    this.persistDraft(false)
  }

  insertElement(event) {
    const type = event.currentTarget.dataset.type
    const selectionStart = this.codeTarget.selectionStart
    const selectionEnd = this.codeTarget.selectionEnd
    let snippet = ""

    switch (type) {
      case "rect":
        snippet = "<rect x='20' y='20' width='120' height='80' fill='#ec6724' stroke='#1f2f45' stroke-width='3' />"
        break
      case "circle":
        snippet = "<circle cx='160' cy='80' r='40' fill='#2467ef' stroke='#10203a' stroke-width='3' />"
        break
      case "line":
        snippet = "<line x1='40' y1='200' x2='240' y2='280' stroke='#22c55e' stroke-width='6' />"
        break
      case "text":
        snippet = "<text x='40' y='170' font-family='Workbench, sans-serif' font-size='24' fill='#1f2f45'>Hello</text>"
        break
      default:
        return
    }

    const original = this.codeTarget.value
    this.codeTarget.value = original.slice(0, selectionStart) + snippet + original.slice(selectionEnd)
    this.codeTarget.focus()
    this.updatePreview()
  }

  setThemeColor(event) {
    const color = event.currentTarget.value
    this.element.style.setProperty("--accent", color)
    this.markDirty()
    this.persistDraft(false)
  }

  toggleMode() {
    this.forceDarkMode = !this.forceDarkMode
    this.element.classList.toggle("editor-force-dark", this.forceDarkMode)
  }

  undo() {
    if (this.history.length < 2) return
    const current = this.history.pop()
    this.future.push(current)
    const previous = this.history[this.history.length - 1]
    this.codeTarget.value = previous
    this.updatePreview()
  }

  redo() {
    if (this.future.length === 0) return
    const next = this.future.pop()
    this.codeTarget.value = next
    this.history.push(next)
    this.updatePreview()
  }

  pushHistory(code) {
    if (this.history.length === 0 || this.history[this.history.length - 1] !== code) {
      this.history.push(code)
      if (this.history.length > 100) this.history.shift()
      this.future = []
    }
  }

  markDirty() {
    this.hasUpdates = true
    this.updateSaveState("Unsaved changes")
  }

  saveNow(event) {
    event.preventDefault()
    this.syncHiddenCode()
    this.persistDraft(false)
    this.updateSaveState("Saving...")
    this.element.querySelector("form").requestSubmit()
  }

  syncHiddenCode() {
    this.svgCodeTarget.value = this.wrapWithRoot(this.codeTarget.value)
    this.elapsedSecondsTarget.value = this.recordedSeconds
  }

  submit(event) {
    this.syncHiddenCode()
    this.persistDraft(false)
    this.updateSaveState("Submitting...")
  }

  downloadSvg() {
    const svgData = this.wrapWithRoot(this.codeTarget.value)
    const blob = new Blob([svgData], { type: "image/svg+xml;charset=utf-8" })
    const url = URL.createObjectURL(blob)
    const link = document.createElement("a")
    link.href = url
    link.download = "design.svg"
    document.body.appendChild(link)
    link.click()
    URL.revokeObjectURL(url)
    link.remove()
  }

  defaultSvg() {
    return "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 640 480'><rect x='10' y='10' width='620' height='460' fill='none' stroke='#dce7f3' stroke-width='2' /></svg>"
  }

  defaultRootOpenTag() {
    return "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 640 480'>"
  }

  wrapWithRoot(innerCode) {
    const content = typeof innerCode === "string" ? innerCode : ""
    const openTag = this.rootOpenTag || this.defaultRootOpenTag()
    return `${openTag}${content}</svg>`
  }

  normalizeEditableCode(code) {
    const text = typeof code === "string" ? code : ""
    if (!/<svg[\s>]/i.test(text)) return text
    const parsed = this.splitSvg(text)
    return parsed.innerContent
  }

  splitSvg(svgMarkup) {
    const raw = typeof svgMarkup === "string" ? svgMarkup : ""

    if (!raw.trim()) {
      return {
        rootOpenTag: this.defaultRootOpenTag(),
        innerContent: ""
      }
    }

    if (!/<svg[\s>]/i.test(raw)) {
      return {
        rootOpenTag: this.defaultRootOpenTag(),
        innerContent: raw
      }
    }

    try {
      const parser = new DOMParser()
      const doc = parser.parseFromString(raw, "image/svg+xml")
      const svg = doc.querySelector("svg")

      if (!svg) {
        return {
          rootOpenTag: this.defaultRootOpenTag(),
          innerContent: raw
        }
      }

      const outer = svg.outerHTML || ""
      const openTagMatch = outer.match(/^<svg\b[^>]*>/i)

      return {
        rootOpenTag: openTagMatch ? openTagMatch[0] : this.defaultRootOpenTag(),
        innerContent: svg.innerHTML || ""
      }
    } catch (_error) {
      return {
        rootOpenTag: this.defaultRootOpenTag(),
        innerContent: raw
      }
    }
  }

  persistDraft(updateStatus = true) {
    if (!this.supportsLocalStorage()) return

    this.syncHiddenCode()
    const payload = this.currentDraftPayload()

    try {
      localStorage.setItem(this.draftKey(), JSON.stringify(payload))
      if (updateStatus) this.updateSaveState("Draft saved locally")
    } catch (_error) {
      if (updateStatus) this.updateSaveState("Unable to save local draft")
    }
  }

  restoreDraft() {
    if (!this.supportsLocalStorage()) return

    const raw = localStorage.getItem(this.draftKey())
    if (!raw) return

    try {
      const draft = JSON.parse(raw)
      if (!draft || typeof draft !== "object") return

      const draftCode = this.normalizeEditableCode(draft.code)
      const codeChanged = typeof draftCode === "string" && draftCode.length > 0 && draftCode !== this.codeTarget.value
      const nameChanged = this.hasNameTarget && typeof draft.name === "string" && draft.name !== this.nameTarget.value
      const descriptionChanged = this.hasDescriptionTarget && typeof draft.description === "string" && draft.description !== this.descriptionTarget.value
      const secondsChanged = Number.isFinite(Number(draft.elapsedSeconds)) && Number(draft.elapsedSeconds) > this.recordedSeconds

      if (!codeChanged && !nameChanged && !descriptionChanged && !secondsChanged) return

      if (codeChanged) this.codeTarget.value = draftCode
      if (nameChanged) this.nameTarget.value = draft.name
      if (descriptionChanged) this.descriptionTarget.value = draft.description
      if (secondsChanged) this.recordedSeconds = Number(draft.elapsedSeconds)

      this.syncHiddenCode()
      this.updateRootLockLines()
      this.updateTimerDisplay()
      this.hasUpdates = true
      this.updateSaveState("Recovered unsaved draft")
    } catch (_error) {
      this.updateSaveState("Draft restore skipped")
    }
  }

  flushBeforeLeave() {
    this.persistDraft(false)

    if (!this.persistedValue) return
    if (!this.hasPendingServerSync()) return
    if (!this.autosaveUrlValue || typeof navigator.sendBeacon !== "function") return

    const form = this.element.querySelector("form")
    if (!form) return

    const payload = new FormData()
    const token = form.querySelector("input[name='authenticity_token']")?.value
    const method = form.querySelector("input[name='_method']")?.value

    if (token) payload.append("authenticity_token", token)
    if (method) payload.append("_method", method)

    payload.append("design[name]", this.hasNameTarget ? this.nameTarget.value : "Untitled Design")
    payload.append("design[description]", this.hasDescriptionTarget ? this.descriptionTarget.value : "Draft description")
    payload.append("design_svg_code", this.wrapWithRoot(this.codeTarget.value))
    payload.append("elapsed_seconds", String(this.recordedSeconds))

    navigator.sendBeacon(this.autosaveUrlValue, payload)
  }

  hasPendingServerSync() {
    return this.hasUpdates || this.recordedSeconds > this.initialSeconds
  }

  currentDraftPayload() {
    return {
      name: this.hasNameTarget ? this.nameTarget.value : "",
      description: this.hasDescriptionTarget ? this.descriptionTarget.value : "",
      code: this.codeTarget.value,
      elapsedSeconds: this.recordedSeconds,
      updatedAt: Date.now()
    }
  }

  draftKey() {
    return this.storageKeyValue || "design-editor:draft"
  }

  supportsLocalStorage() {
    try {
      return typeof window !== "undefined" && typeof window.localStorage !== "undefined"
    } catch (_error) {
      return false
    }
  }

  updateSaveState(message) {
    if (this.hasSaveStateTarget) {
      this.saveStateTarget.textContent = message
    }
  }

  updateRootLockLines() {
    if (this.hasRootOpenTarget) this.rootOpenTarget.textContent = this.rootOpenTag || this.defaultRootOpenTag()
    if (this.hasRootCloseTarget) this.rootCloseTarget.textContent = this.rootCloseTag || "</svg>"
  }
}

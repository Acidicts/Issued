import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list"]
  static values = {
    currentPath: String,
    unreadCount: Number,
    isAdmin: Boolean
  }

  connect() {
    this.renderTabs()
  }

  get tabs() {
    return this.TABS.filter(tab => !tab.adminOnly || this.isAdminValue)
  }

  // ── Tab configuration ──────────────────────────────────────────
  // `url` can be a string or an array of strings.
  // An array means the tab is active on any of those paths,
  // and the link goes to the first one.
  // ────────────────────────────────────────────────────────────────
  TABS = [
    { label: "Dashboard",     url: "/dashboard",     nav: "dashboard" },
    { label: "My Designs",    url: "/designs",       nav: "designs" },
    { label: "The Loom",      url: ["/shop", "/orders"], nav: "shop" },
    { label: "Notifications", url: "/notifications", nav: "notifications", badge: true },
    { label: "Admin",         url: "/admin",         adminOnly: true }
  ]

  renderTabs() {
    this.listTarget.innerHTML = ""

    this.tabs.forEach(tab => {
      const a = document.createElement("a")
      const urls = Array.isArray(tab.url) ? tab.url : [tab.url]
      a.href = urls[0]
      a.className = "tab"
      a.textContent = tab.label

      if (this.isActive(urls)) {
        a.classList.add("active")
      }

      if (tab.badge && this.unreadCountValue > 0) {
        const pip = document.createElement("span")
        pip.className = "pip"
        pip.dataset.navigationTabsTarget = "badge"
        pip.textContent = this.unreadCountValue
        a.appendChild(pip)
      }

      this.listTarget.appendChild(a)
    })
  }

  isActive(urls) {
    const path = this.currentPathValue
    return urls.some(url => {
      if (url === "/") return path === "/"
      return path === url || path.startsWith(url + "/")
    })
  }

  updateCount(event) {
    const params = event.detail?.params
    if (params?.count !== undefined) {
      this.unreadCountValue = params.count
      this.renderTabs()
    }
  }
}

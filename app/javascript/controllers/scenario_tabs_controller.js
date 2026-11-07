import { Controller } from "@hotwired/stimulus"

// Tabs that switch the health table between the Trinity study stock/bond mixes.
export default class extends Controller {
  static targets = ["tab", "panel", "subtitle"]

  static SCENARIOS_KEY = "healthTableScenario"
  static DEFAULT_SCENARIO = "100"

  connect() {
    this.show(this.stored)
  }

  select(event) {
    const key = event.currentTarget.dataset.scenario
    try { localStorage.setItem(this.constructor.SCENARIOS_KEY, key) } catch (e) {}
    this.show(key)
  }

  get stored() {
    let stored = null
    try { stored = localStorage.getItem(this.constructor.SCENARIOS_KEY) } catch (e) {}
    const keys = this.panelTargets.map(panel => panel.dataset.scenario)
    return keys.includes(stored) ? stored : this.constructor.DEFAULT_SCENARIO
  }

  show(key) {
    this.panelTargets.forEach((panel) => {
      const active = panel.dataset.scenario === key
      panel.classList.toggle("hidden", !active)
      if (active && this.hasSubtitleTarget) {
        this.subtitleTarget.textContent = `${panel.dataset.label} portfolio value at each milestone, adjusted for inflation-indexed withdrawals`
      }
    })
    this.tabTargets.forEach((tab) => {
      const active = tab.dataset.scenario === key
      tab.setAttribute("aria-selected", String(active))
      tab.classList.toggle("bg-white", active)
      tab.classList.toggle("shadow-sm", active)
      const color = this.colorFor(tab)
      tab.style.borderColor = active ? color : ""
      tab.style.color = active ? color : ""
    })
    this.element.dataset.activeScenario = key
  }

  colorFor(tab) {
    return tab.querySelector("span").style.backgroundColor
  }
}

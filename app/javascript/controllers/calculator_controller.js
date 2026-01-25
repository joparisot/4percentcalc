import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "rate", "rateDisplay"]

  connect() {
    this.timeout = null
  }

  updateRate() {
    if (this.hasRateDisplayTarget && this.hasRateTarget) {
      this.rateDisplayTarget.textContent = this.rateTarget.value
    }
    this.debounceSubmit()
  }

  debounceSubmit() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.submit()
    }, 500)
  }

  submit() {
    if (this.hasFormTarget) {
      this.formTarget.requestSubmit()
    }
  }
}

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "rate", "rateDisplay", "amount"]

  connect() {
    this.timeout = null
  }

  updateRate() {
    if (this.hasRateDisplayTarget && this.hasRateTarget) {
      this.rateDisplayTarget.textContent = this.rateTarget.value
    }
  }

  debounceSubmit() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.submit()
    }, 300)
  }

  submit() {
    if (this.hasFormTarget) {
      this.formTarget.requestSubmit()
    }
  }
}

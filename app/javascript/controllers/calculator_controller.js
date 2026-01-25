import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "rate", "rateDisplay", "amountDisplay", "amountHidden"]

  connect() {
    this.timeout = null
  }

  updateRate() {
    if (this.hasRateDisplayTarget && this.hasRateTarget) {
      this.rateDisplayTarget.textContent = this.rateTarget.value
    }
    this.debounceSubmit()
  }

  updateAmount() {
    if (this.hasAmountDisplayTarget && this.hasAmountHiddenTarget) {
      // Parse the display value (remove commas)
      const rawValue = this.amountDisplayTarget.value.replace(/,/g, '')
      const numValue = parseInt(rawValue) || 0

      // Clamp to min/max
      const clampedValue = Math.min(Math.max(numValue, 1000), 100000000)

      // Update hidden field with raw number
      this.amountHiddenTarget.value = clampedValue

      // Update display with formatted number
      this.amountDisplayTarget.value = clampedValue.toLocaleString()
    }
    this.debounceSubmit()
  }

  incrementAmount() {
    if (this.hasAmountHiddenTarget && this.hasAmountDisplayTarget) {
      const currentValue = parseInt(this.amountHiddenTarget.value) || 1000000
      const newValue = Math.min(currentValue + 100000, 100000000)
      this.amountHiddenTarget.value = newValue
      this.amountDisplayTarget.value = newValue.toLocaleString()
      this.debounceSubmit()
    }
  }

  decrementAmount() {
    if (this.hasAmountHiddenTarget && this.hasAmountDisplayTarget) {
      const currentValue = parseInt(this.amountHiddenTarget.value) || 1000000
      const newValue = Math.max(currentValue - 100000, 1000)
      this.amountHiddenTarget.value = newValue
      this.amountDisplayTarget.value = newValue.toLocaleString()
      this.debounceSubmit()
    }
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

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "rate", "rateDisplay", "amountDisplay", "amountHidden", "shareLabel"]

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

  copyLink() {
    const params = new URLSearchParams()
    if (this.hasAmountHiddenTarget) params.set('initial_amount', this.amountHiddenTarget.value)
    if (this.hasRateTarget) params.set('withdrawal_rate', this.rateTarget.value)
    const horizon = document.getElementById('horizon_hidden')
    if (horizon && horizon.value) params.set('horizon', horizon.value)

    const url = `${window.location.origin}${window.location.pathname}?${params.toString()}`

    const onSuccess = () => {
      if (!this.hasShareLabelTarget) return
      const label = this.shareLabelTarget
      const original = label.textContent
      label.textContent = 'Link copied!'
      setTimeout(() => { label.textContent = original }, 2000)
    }

    if (navigator.clipboard && window.isSecureContext) {
      navigator.clipboard.writeText(url).then(onSuccess)
    } else {
      const textarea = document.createElement('textarea')
      textarea.value = url
      textarea.style.position = 'fixed'
      textarea.style.opacity = '0'
      document.body.appendChild(textarea)
      textarea.select()
      document.execCommand('copy')
      document.body.removeChild(textarea)
      onSuccess()
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

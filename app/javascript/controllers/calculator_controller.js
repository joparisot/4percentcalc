import { Controller } from "@hotwired/stimulus"

const AMOUNT_RANGE = { min: 1000, max: 100000000, step: 100000 }
const SPENDING_RANGE = { min: 1000, max: 1000000, step: 5000 }

export default class extends Controller {
  static targets = [
    "form", "rate", "rateDisplay", "amountDisplay", "amountHidden", "shareLabel",
    "spendingDisplay", "spendingHidden", "requiredAmount", "requiredSpending", "requiredRate"
  ]

  connect() {
    this.timeout = null
  }

  updateRate() {
    if (this.hasRateDisplayTarget && this.hasRateTarget) {
      this.rateDisplayTarget.textContent = this.rateTarget.value
    }
    this.updateRequiredPortfolio()
    this.debounceSubmit()
  }

  updateAmount() {
    if (this.hasAmountDisplayTarget && this.hasAmountHiddenTarget) {
      this.syncTypedValue(this.amountDisplayTarget, this.amountHiddenTarget, AMOUNT_RANGE)
    }
    this.debounceSubmit()
  }

  incrementAmount() {
    this.stepAmount(1)
  }

  decrementAmount() {
    this.stepAmount(-1)
  }

  updateSpending() {
    if (this.hasSpendingDisplayTarget && this.hasSpendingHiddenTarget) {
      this.syncTypedValue(this.spendingDisplayTarget, this.spendingHiddenTarget, SPENDING_RANGE)
    }
    this.updateRequiredPortfolio()
    this.debounceSubmit()
  }

  incrementSpending() {
    this.stepSpending(1)
  }

  decrementSpending() {
    this.stepSpending(-1)
  }

  // Carries the visible value over so switching modes keeps the same scenario.
  changeMode() {
    clearTimeout(this.timeout)
    const amount = this.formTarget.elements['initial_amount']
    const spending = this.formTarget.elements['annual_spending']
    const rate = parseFloat(this.rateTarget.value)
    if (this.hasSpendingHiddenTarget) {
      amount.value = Math.round(spending.value * 100 / rate)
    } else {
      spending.value = Math.round(amount.value * rate / 100)
    }
    this.submit()
  }

  stepAmount(direction) {
    if (this.hasAmountHiddenTarget && this.hasAmountDisplayTarget) {
      this.stepValue(this.amountDisplayTarget, this.amountHiddenTarget, AMOUNT_RANGE, direction)
      this.debounceSubmit()
    }
  }

  stepSpending(direction) {
    if (this.hasSpendingHiddenTarget && this.hasSpendingDisplayTarget) {
      this.stepValue(this.spendingDisplayTarget, this.spendingHiddenTarget, SPENDING_RANGE, direction)
      this.updateRequiredPortfolio()
      this.debounceSubmit()
    }
  }

  // Mirrors the typed number into the hidden field. The minimum is only applied to the
  // submitted value so typing "80000" isn't bumped to the minimum after the first digit.
  syncTypedValue(display, hidden, range) {
    const numValue = Math.min(parseInt(display.value.replace(/,/g, '')) || 0, range.max)
    hidden.value = Math.max(numValue, range.min)
    display.value = numValue.toLocaleString()
  }

  stepValue(display, hidden, range, direction) {
    const currentValue = parseInt(hidden.value) || range.min
    const newValue = Math.min(Math.max(currentValue + direction * range.step, range.min), range.max)
    hidden.value = newValue
    display.value = newValue.toLocaleString()
  }

  // Updates the "You need $X" sentence immediately; the backtest refreshes after the debounce.
  updateRequiredPortfolio() {
    if (!this.hasRequiredAmountTarget || !this.hasSpendingHiddenTarget || !this.hasRateTarget) return

    const spending = parseInt(this.spendingHiddenTarget.value) || 0
    const rate = parseFloat(this.rateTarget.value)
    this.requiredAmountTarget.textContent = this.formatCurrency(Math.round(spending * 100 / rate))
    if (this.hasRequiredSpendingTarget) this.requiredSpendingTarget.textContent = this.formatCurrency(spending)
    if (this.hasRequiredRateTarget) this.requiredRateTarget.textContent = String(rate)
  }

  formatCurrency(value) {
    return `$${value.toLocaleString('en-US')}`
  }

  shareUrl() {
    const params = new URLSearchParams()
    if (this.hasSpendingHiddenTarget) {
      params.set('annual_spending', this.spendingHiddenTarget.value)
    } else if (this.hasAmountHiddenTarget) {
      params.set('initial_amount', this.amountHiddenTarget.value)
    }
    if (this.hasRateTarget) params.set('withdrawal_rate', parseFloat(this.rateTarget.value).toFixed(1))
    const horizon = document.getElementById('horizon_hidden')
    if (horizon && horizon.value) params.set('horizon', horizon.value)
    const allocation = document.getElementById('stock_allocation_hidden')
    if (allocation && allocation.value && allocation.value !== '50') params.set('stock_allocation', allocation.value)
    const fee = this.hasFormTarget && this.formTarget.elements['fee']
    if (fee && parseFloat(fee.value) > 0) params.set('fee', fee.value)

    return `${window.location.origin}${window.location.pathname}?${params.toString()}`
  }

  copyLink() {
    const url = this.shareUrl()

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

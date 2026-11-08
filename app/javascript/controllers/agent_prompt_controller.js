import { Controller } from "@hotwired/stimulus"
import { buildAgentPrompt } from "controllers/agent_prompt"
import { copyToClipboard } from "controllers/clipboard"

export default class extends Controller {
  static targets = ["label"]
  static values = { initialAmount: Number, withdrawalRate: Number, fee: Number, horizon: { type: Number, default: 30 }, startingYear: Number }

  copy() {
    const params = {
      initial_amount: this.initialAmountValue,
      withdrawal_rate: this.withdrawalRateValue,
      horizon: this.horizonValue,
      fee: this.feeValue
    }
    const prompt = buildAgentPrompt(params, window.location.origin, this.startingYearValue || null)
    copyToClipboard(prompt, this.hasLabelTarget ? this.labelTarget : null, 'Prompt copied!')
  }
}

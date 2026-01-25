import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  select(event) {
    const year = this.element.dataset.year
    const initialAmount = this.element.dataset.initialAmount
    const withdrawalRate = this.element.dataset.withdrawalRate

    // Highlight selected row
    document.querySelectorAll('[data-controller="row-select"]').forEach(row => {
      row.classList.remove('bg-[#EDE9FE]')
    })
    this.element.classList.add('bg-[#EDE9FE]')

    // Fetch year detail via Turbo
    const url = `/year_detail/${year}?initial_amount=${initialAmount}&withdrawal_rate=${withdrawalRate}`

    fetch(url, {
      headers: {
        Accept: "text/vnd.turbo-stream.html"
      }
    })
    .then(response => response.text())
    .then(html => {
      Turbo.renderStreamMessage(html)
    })
  }
}

import { Controller } from "@hotwired/stimulus"

// Picks which Trinity study stock/bond mix the charts compare against the S&P 500.
export default class extends Controller {
  select(event) {
    const field = document.getElementById("stock_allocation_hidden")
    if (!field) return

    field.value = event.params.value
    field.form.requestSubmit()
  }
}

require "test_helper"

class ReverseCalculatorTest < ActionDispatch::SystemTestCase
  def horizon_chart_initial_amount
    page.evaluate_script(<<~JS)
      (() => {
        const el = document.querySelector("[data-controller~='horizon-chart']")
        return window.Stimulus.getControllerForElementAndIdentifier(el, "horizon-chart").chart.data.datasets[1].data[0]
      })()
    JS
  end

  def share_url
    page.evaluate_script(<<~JS)
      (() => {
        const el = document.querySelector("[data-controller~='calculator']")
        return window.Stimulus.getControllerForElementAndIdentifier(el, "calculator").shareUrl()
      })()
    JS
  end

  test "spending mode computes the required portfolio, reruns the backtest, and round-trips the share link" do
    visit root_path
    assert_selector "canvas[data-horizon-chart-target='canvas'][width]", wait: 3

    find("label", text: "I know my spending").click
    spending = find("[data-calculator-target='spendingDisplay']", wait: 5)
    spending.fill_in with: "80000"

    assert_selector "[data-calculator-target='requiredAmount']", text: "$2,000,000"
    assert_selector "p", text: %r{You need \$2,000,000 to withdraw \$80,000/yr at 4%}, wait: 5
    assert_selector "[data-horizon-chart-initial-amount-value='2000000']", wait: 5
    assert_selector "canvas[data-horizon-chart-target='canvas'][width]", wait: 5
    assert_equal 2_000_000, horizon_chart_initial_amount

    url = URI(share_url)
    assert_equal({ "annual_spending" => "80000", "withdrawal_rate" => "4.0", "horizon" => "30" }, URI.decode_www_form(url.query).to_h)

    visit "#{url.path}?#{url.query}"
    assert_selector "input[type='radio'][value='spending']:checked", visible: :all
    assert_equal "80,000", find("[data-calculator-target='spendingDisplay']").value
    assert_selector "[data-calculator-target='requiredAmount']", text: "$2,000,000"
    assert_selector "canvas[data-horizon-chart-target='canvas'][width]", wait: 3
    assert_equal 2_000_000, horizon_chart_initial_amount
  end

  test "changing the rate in spending mode updates the required portfolio live" do
    visit root_path(annual_spending: 80_000, withdrawal_rate: 4.0)
    find("input[type='range'][data-calculator-target='rate']").set(3.5)

    assert_selector "[data-calculator-target='requiredAmount']", text: "$2,285,714"
    assert_selector "[data-horizon-chart-initial-amount-value='2285714']", wait: 5
  end

  test "switching back to portfolio mode keeps the scenario" do
    visit root_path(annual_spending: 80_000, withdrawal_rate: 4.0)
    find("label", text: "I know my portfolio").click

    assert_equal "2,000,000", find("[data-calculator-target='amountDisplay']", wait: 5).value
  end
end

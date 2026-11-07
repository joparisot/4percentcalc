require "test_helper"

class WithdrawalRateInputTest < ActionDispatch::SystemTestCase
  RATE_BOX = "input[data-calculator-target='rateDisplay']"
  SLIDER = "input[type='range'][data-calculator-target='rate']"

  def chart_first_balance
    page.evaluate_script(<<~JS)
      (() => {
        const el = document.querySelector("[data-controller~='horizon-chart']")
        return window.Stimulus.getControllerForElementAndIdentifier(el, "horizon-chart").chart.data.datasets[1].data[0]
      })()
    JS
  end

  def current_query
    URI.decode_www_form(URI(page.current_url).query.to_s).to_h
  end

  def wait_for_chart
    assert_selector "canvas[data-horizon-chart-target='canvas'][width]", wait: 5
  end

  test "typing a rate and pressing Enter reruns the backtest and updates the URL" do
    visit root_path
    wait_for_chart
    before = chart_first_balance

    box = find(RATE_BOX)
    box.fill_in with: "3.7"
    box.send_keys :enter

    assert_selector "#{SLIDER}[value='3.7']", wait: 5
    assert_equal "3.7", find(RATE_BOX).value
    wait_for_chart
    refute_equal before, chart_first_balance
    assert_equal "3.7", current_query["withdrawal_rate"]
    assert_equal "1000000", current_query["initial_amount"]
    assert_not page.evaluate_script("document.activeElement.matches(#{RATE_BOX.to_json})")
  end

  test "leaving the rate box commits the typed rate, clamped to the slider range" do
    visit root_path
    wait_for_chart

    find(RATE_BOX).fill_in with: "20"
    find("h2", text: "Portfolio Parameters").click

    assert_selector "#{SLIDER}[value='12']", wait: 5
    assert_equal "12", find(RATE_BOX).value
    assert_equal "12.0", current_query["withdrawal_rate"]
  end

  test "an unreadable rate reverts to the current one without resubmitting" do
    visit root_path(withdrawal_rate: 4.5)
    wait_for_chart

    box = find(RATE_BOX)
    box.fill_in with: "abc"
    box.send_keys :enter

    assert_equal "4.5", find(RATE_BOX).value
    assert_equal "4.5", find(SLIDER).value
  end

  test "negative rates clamp to the minimum and text mixed with digits is rejected" do
    visit root_path(withdrawal_rate: 4.5)
    wait_for_chart

    box = find(RATE_BOX)
    box.fill_in with: "abc8"
    box.send_keys :enter
    assert_equal "4.5", find(RATE_BOX).value
    assert_equal "4.5", find(SLIDER).value

    box = find(RATE_BOX)
    box.fill_in with: "-2"
    box.send_keys :enter
    assert_selector "#{SLIDER}[value='1']", wait: 5
    assert_equal "1", find(RATE_BOX).value

    box = find(RATE_BOX)
    box.fill_in with: "3,5 %"
    box.send_keys :enter
    assert_selector "#{SLIDER}[value='3.5']", wait: 5
    assert_equal "3.5", current_query["withdrawal_rate"]
  end

  test "moving the slider updates the rate box, the chart and the URL" do
    visit root_path
    wait_for_chart
    before = chart_first_balance

    find(SLIDER).set(6)

    assert_selector "#{SLIDER}[value='6']", wait: 5
    assert_equal "6", find(RATE_BOX).value
    wait_for_chart
    refute_equal before, chart_first_balance
    assert_equal "6.0", current_query["withdrawal_rate"]

    visit page.current_url
    assert_equal "6", find(RATE_BOX).value
  end

  test "changing the horizon keeps the URL in sync" do
    visit root_path
    wait_for_chart

    select "20 years", from: "horizon-select"
    assert_equal "20", current_query["horizon"]
  end

  test "a slow drag on the slider commits where the pointer is released" do
    visit root_path
    wait_for_chart

    slider = find(SLIDER)
    width = page.evaluate_script("arguments[0].getBoundingClientRect().width", slider)
    step = ((width - 16) * 0.2).to_i
    # One action chain: separate perform calls end the drag in Chrome. Each pause outlasts the old 500ms debounce.
    page.driver.browser.action
      .move_to(slider.native, -(width / 2).to_i + 8, 0).click_and_hold
      .pause(duration: 0.7).move_by(step, 0)
      .pause(duration: 0.7).move_by(step, 0)
      .pause(duration: 0.7).move_by(step, 0)
      .pause(duration: 0.7).release.perform

    final = find(SLIDER).value
    assert_operator final.to_f, :>, 6
    assert_selector "#{SLIDER}[value='#{final}']", wait: 5
    assert_equal final, find(RATE_BOX).value
    assert_equal format("%.1f", final.to_f), current_query["withdrawal_rate"]
  end
end

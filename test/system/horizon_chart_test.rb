require "test_helper"

class HorizonChartTest < ActionDispatch::SystemTestCase
  test "chart canvas renders on page load" do
    visit root_path
    assert_selector "canvas[data-horizon-chart-target='canvas']"
  end

  test "chart renders within 3 seconds" do
    visit root_path

    # Chart.js creates a canvas with specific attributes when rendered
    # We check that the canvas has width/height set (Chart.js does this on render)
    canvas = find("canvas[data-horizon-chart-target='canvas']")

    # Wait up to 3 seconds for chart to render (Chart.js sets these attributes)
    assert_selector "canvas[data-horizon-chart-target='canvas'][width]", wait: 3
  end

  test "dropdown shows all horizon options" do
    visit root_path

    within "select[data-horizon-chart-target='dropdown']" do
      assert_selector "option", count: 5
      assert_selector "option[value='10']", text: "10 years"
      assert_selector "option[value='20']", text: "20 years"
      assert_selector "option[value='30']", text: "30 years"
      assert_selector "option[value='40']", text: "40 years"
      assert_selector "option[value='50']", text: "50 years"
    end
  end

  test "default horizon is 30 years" do
    visit root_path

    dropdown = find("select[data-horizon-chart-target='dropdown']")
    assert_equal "30", dropdown.value

    title = find("[data-horizon-chart-target='title']")
    assert_includes title.text, "30 Years"
  end

  test "dropdown changes update chart title" do
    visit root_path

    select "20 years", from: "horizon-select"

    title = find("[data-horizon-chart-target='title']")
    assert_includes title.text, "20 Years"
  end

  test "chart survives Turbo updates" do
    visit root_path

    # Wait for initial chart render
    assert_selector "canvas[data-horizon-chart-target='canvas'][width]", wait: 3

    # Change withdrawal rate to trigger Turbo update
    slider = find("input[type='range'][data-calculator-target='rate']")
    slider.set(5)

    # Wait for Turbo update to complete and chart to re-render
    sleep 1 # Give debounce time to trigger
    assert_selector "canvas[data-horizon-chart-target='canvas'][width]", wait: 5
  end

  test "initial amount legend label has a single dollar sign" do
    visit root_path
    assert_selector "canvas[data-horizon-chart-target='canvas'][width]", wait: 3

    label = page.evaluate_script(<<~JS)
      (() => {
        const el = document.querySelector("[data-controller~='horizon-chart']")
        const ctrl = window.Stimulus.getControllerForElementAndIdentifier(el, "horizon-chart")
        return ctrl.chart.data.datasets[0].label
      })()
    JS

    assert_match(/\AInitial Amount \(\$\d/, label)
    refute_includes label, "$$"
  end

  test "horizon selection persists through Turbo updates" do
    visit root_path

    # Select 20 year horizon
    select "20 years", from: "horizon-select"

    # Change withdrawal rate to trigger Turbo update
    slider = find("input[type='range'][data-calculator-target='rate']")
    slider.set(6)

    # Wait for update
    sleep 1

    # Horizon should still be 20
    dropdown = find("select[data-horizon-chart-target='dropdown']", wait: 5)
    assert_equal "20", dropdown.value
  end

  test "start years without enough history are marked N/A instead of cutting the axis short" do
    visit root_path
    canvas = "canvas[data-horizon-chart-target='canvas']"
    last_year = Calculator.new.available_years.last
    assert_selector "#{canvas}[data-na-from='#{last_year - 28}']", wait: 3

    select "50 years", from: "horizon-select"
    assert_selector "#{canvas}[data-na-from='#{last_year - 48}']"

    select "10 years", from: "horizon-select"
    assert_selector "#{canvas}[data-na-from='']"
  end

  test "legend explains the red band" do
    visit root_path
    within "[data-horizon-legend]" do
      assert_text "Below the starting amount"
      refute_text "1–4×"
    end
  end

  test "major market events are marked on the horizon and year-detail charts" do
    visit root_path
    canvas = "canvas[data-horizon-chart-target='canvas']"
    assert_selector "#{canvas}[data-marked-events='1929,1973,1987,2000,2008']", wait: 3
    assert_text "Major market event"

    visit year_detail_path(2000)
    assert_selector "canvas[data-chart-target='canvas'][data-marked-events='2000,2008,2020']", wait: 3
    assert_text "Major market event"
  end


  test "scenario chips add and remove lines without reloading" do
    visit root_path
    page.execute_script("localStorage.clear()")
    visit root_path
    canvas = "canvas[data-horizon-chart-target='canvas']"
    chip = ->(key) { find("[data-horizon-chart-target='chip'][data-scenario='#{key}']") }
    assert_selector "#{canvas}[width][data-rendered-scenarios='sp500,sp50']", wait: 3
    assert_equal ["100% S&P 500", "50/50 stocks/bonds"], chart_dataset_labels.drop(1)

    chip.call('sp75').click
    assert_selector "#{canvas}[data-rendered-scenarios='sp500,sp75,sp50']"
    assert_equal ["100% S&P 500", "75/25 stocks/bonds", "50/50 stocks/bonds"], chart_dataset_labels.drop(1)

    chip.call('sp500').click
    assert_selector "#{canvas}[data-rendered-scenarios='sp75,sp50']"
    assert_equal ["75/25 stocks/bonds", "50/50 stocks/bonds"], chart_dataset_labels.drop(1)

    chip.call('sp50').click
    assert_selector "#{canvas}[data-rendered-scenarios='sp75']"
    assert_selector "[data-horizon-chart-target='chip'][data-scenario='sp75'][aria-disabled='true']"
    chip.call('sp75').click
    assert_selector "#{canvas}[data-rendered-scenarios='sp75']"

    select "20 years", from: "horizon-select"
    assert_selector "#{canvas}[data-rendered-scenarios='sp75']"

    chip.call("nasdaq").click
    assert_selector "#{canvas}[data-rendered-scenarios='sp75,nasdaq']"
    assert_includes chart_dataset_labels, "100% Nasdaq Composite"
  ensure
    page.execute_script("localStorage.clear()")
  end

  private

  def chart_dataset_labels
    page.evaluate_async_script(<<~JS)
      const done = arguments[0]
      const poll = () => {
        const controller = window.Stimulus?.getControllerForElementAndIdentifier(document.querySelector("[data-controller='horizon-chart']"), "horizon-chart")
        if (controller?.chart) return done(controller.chart.data.datasets.map(d => d.label))
        setTimeout(poll, 50)
      }
      poll()
    JS
  end
end

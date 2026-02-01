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
end

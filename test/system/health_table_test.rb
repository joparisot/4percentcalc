require "test_helper"

class HealthTableTest < ActionDispatch::SystemTestCase
  test "tabs switch the health table between Trinity mixes and survive Turbo updates" do
    visit root_path
    page.execute_script("localStorage.clear()")
    visit root_path

    assert_selector "#start-years[data-active-scenario='sp500']"
    assert_selector "#start-years [data-scenario-tabs-target='panel']", count: 1

    find("#start-years [role='tab']", text: "50/50 stocks/bonds").click
    assert_selector "#start-years[data-active-scenario='sp50']"
    assert_selector "[data-scenario-tabs-target='subtitle']", text: /\A50\/50 stocks\/bonds/
    assert_selector "#start-years [data-scenario-tabs-target='panel']", count: 1
    assert_selector "#start-years table[data-scenario='sp50'] tbody tr:first-child a[href^='/year_detail']"

    find("input[type='range'][data-calculator-target='rate']").set(5)
    sleep 1
    assert_selector "canvas[data-horizon-chart-target='canvas'][width]", wait: 5
    assert_selector "#start-years[data-active-scenario='sp50']"
  ensure
    page.execute_script("localStorage.clear()")
  end
end

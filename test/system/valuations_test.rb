require "test_helper"

class ValuationsTest < ActionDispatch::SystemTestCase
  test "valuations page renders the timeline and bucket table" do
    visit valuations_path

    assert_selector "[data-controller='valuation-timeline'] canvas[data-rendered='true']", wait: 5
    assert_selector "table[data-valuation-buckets] tbody tr", maximum: 4
    assert_selector "table[data-valuation-buckets]", text: "Under 15"
  end

  test "year detail shows a CAPE chip linking to valuations" do
    visit year_detail_path(1966)

    link = find_link(text: /CAPE at start: 24\.\d/)
    assert_equal valuations_path, URI(link[:href]).path
  end

  test "timeline horizon selector updates the heading" do
    visit valuations_path
    within("[data-controller='valuation-timeline']") do
      select "10 years", from: "timeline-horizon-select"
      assert_selector "h2", text: "what 10 years left"
      assert_selector "canvas[data-rendered='true']"
    end
  end

  test "timeline strategy chips add lines" do
    visit valuations_path
    page.execute_script("localStorage.clear()")
    visit valuations_path
    canvas = "canvas[data-valuation-timeline-target='canvas']"
    assert_selector "#{canvas}[data-rendered='true'][data-rendered-scenarios='sp500']", wait: 5

    find("[data-valuation-timeline-target='chip'][data-scenario='sp50']").click
    assert_selector "#{canvas}[data-rendered-scenarios='sp500,sp50']"
    assert_selector "[data-valuation-timeline-target='chip'][data-scenario='sp50'][aria-pressed='true']"
    assert_selector "#{canvas}[data-rendered='true']"
  ensure
    page.execute_script("localStorage.clear()")
  end
end

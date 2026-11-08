require "test_helper"

class ValuationsTest < ActionDispatch::SystemTestCase
  test "valuations page renders the chart and bucket table" do
    visit valuations_path

    assert_selector "[data-controller='valuation-chart'] canvas"
    assert_selector "canvas[data-valuation-chart-target='canvas'][data-rendered='true']", wait: 5
    assert_selector "table[data-valuation-buckets] tbody tr", maximum: 4
    assert_selector "table[data-valuation-buckets]", text: "Under 15"
  end

  test "year detail shows a CAPE chip linking to valuations" do
    visit year_detail_path(1966)

    link = find_link(text: /CAPE at start: 24\.\d/)
    assert_equal valuations_path, URI(link[:href]).path
  end
end

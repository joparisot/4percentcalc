require "test_helper"

class ValuationsControllerTest < ActionDispatch::IntegrationTest
  test "GET /valuations shows CAPE and the today callout" do
    get valuations_path
    assert_response :success
    assert_includes response.body, "CAPE"

    today = ValuationAnalysis.current.today
    assert_includes response.body, "CAPE in January 2026: #{format('%.1f', today[:cape])}"
    assert_includes response.body, "Higher than #{ValuationAnalysis.current.percentile(today[:cape])}%"
    assert_includes response.headers["Cache-Control"], "max-age=86400"
  end

  test "year detail links to valuations with a CAPE chip" do
    get year_detail_path(1966)
    assert_select "a[href='#{valuations_path}']", text: /CAPE at start: 24\.1/
  end
end

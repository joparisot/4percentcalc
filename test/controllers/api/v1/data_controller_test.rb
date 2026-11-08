require "test_helper"

class Api::V1::DataControllerTest < ActionDispatch::IntegrationTest
  test "returns the dataset" do
    get "/api/v1/data"
    assert_response :success
    body = response.parsed_body

    first = body["years"].first
    assert_equal 1926, first["year"]
    assert first.key?("nasdaq_return")
    assert_nil first["nasdaq_return"]
    assert_kind_of Numeric, body["years"].find { |y| y["year"] == 1972 }["nasdaq_return"]
    assert_equal 6, body["scenarios"].size
    assert_equal({ "key" => "sp500", "label" => "100% S&P 500", "stock_allocation" => 100, "first_year" => 1926 }, body["scenarios"].first)
    assert_includes body["sources"]["shiller"], "Robert Shiller"
    assert_includes body["sources"]["nasdaq"], "DQYDJ"
    assert body["meta"]["methodology_url"].present?
  end

  test "is publicly cached" do
    get "/api/v1/data"
    assert_includes response.headers["Cache-Control"], "public"
    assert_includes response.headers["Cache-Control"], "max-age=86400"
    assert response.headers["ETag"].present?
  end
end

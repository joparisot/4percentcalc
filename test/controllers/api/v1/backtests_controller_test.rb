require "test_helper"

class Api::V1::BacktestsControllerTest < ActionDispatch::IntegrationTest
  test "default call returns inputs, summary, results and meta" do
    get "/api/v1/backtest"
    assert_response :success
    body = response.parsed_body

    assert_equal %w[inputs summary results meta], body.keys
    assert_equal 1_000_000, body["inputs"]["initial_amount"]
    assert_equal 40_000, body["inputs"]["annual_spending"]
    assert_equal 4.0, body["inputs"]["withdrawal_rate"]
    assert_equal "sp500", body["inputs"]["scenario"]
    assert_equal 30, body["inputs"]["horizon"]
    assert_equal %w[10 20 30 40 50], body["results"].first["milestones"].keys
    assert_equal 1926, body["results"].first["starting_year"]
    assert body["summary"]["success_rate"]
    assert_equal 1926, body["meta"]["data_range"]["first_year"]
    assert_equal "http://www.example.com/methodology.md", body["meta"]["methodology_url"]
    assert_match %r{\Ahttp://www.example.com/\?}, body["meta"]["ui_url"]
  end

  test "annual_spending derives initial_amount" do
    get "/api/v1/backtest", params: { annual_spending: 40_000, withdrawal_rate: 4.0 }
    assert_response :success
    assert_equal 1_000_000, response.parsed_body["inputs"]["initial_amount"]
    assert_equal 40_000, response.parsed_body["inputs"]["annual_spending"]
  end

  test "nasdaq scenario only returns start years from 1972" do
    get "/api/v1/backtest", params: { scenario: "nasdaq" }
    assert_response :success
    years = response.parsed_body["results"].map { |r| r["starting_year"] }
    assert_equal 1972, years.min
    assert_equal "100% Nasdaq Composite", response.parsed_body["inputs"]["scenario_label"]
  end

  test "horizon changes the summary" do
    get "/api/v1/backtest", params: { horizon: 40 }
    assert_response :success
    body = response.parsed_body
    assert_equal 40, body["inputs"]["horizon"]

    results = Calculator.new.backtest_all(initial_amount: 1_000_000, withdrawal_rate: 4.0)
    assert_equal results.count { |r| r[:milestones][40] }, body["summary"]["total_periods"]
  end

  test "rejects invalid inputs with a JSON error that is not cacheable" do
    [
      { withdrawal_rate: 25 }, { fee: 5 }, { horizon: 15 }, { scenario: "foo" },
      { initial_amount: 0 }, { initial_amount: "abc" }, { annual_spending: 0 }
    ].each do |params|
      get "/api/v1/backtest", params: params
      assert_response :bad_request, params.inspect
      assert response.parsed_body["error"].present?, params.inspect
      assert_match(/no-store|no-cache/, response.headers["Cache-Control"], params.inspect)
    end
  end

  test "ignores unknown params" do
    get "/api/v1/backtest", params: { bogus: "1" }
    assert_response :success
  end

  test "success responses are publicly cached for a day with an ETag" do
    get "/api/v1/backtest"
    assert_response :success
    assert_includes response.headers["Cache-Control"], "public"
    assert_includes response.headers["Cache-Control"], "max-age=86400"
    assert response.headers["ETag"].present?

    get "/api/v1/backtest", headers: { "If-None-Match" => response.headers["ETag"] }
    assert_response :not_modified
  end

  test "single year returns result and series" do
    get "/api/v1/backtest/1966"
    assert_response :success
    body = response.parsed_body

    assert_equal 1966, body["result"]["starting_year"]
    assert_equal({ "year" => 0, "value" => 1_000_000 }, body["series"].first)
    assert_match %r{/year_detail/1966\?}, body["meta"]["ui_url"]
    assert_includes response.headers["Cache-Control"], "max-age=86400"
  end

  test "single year series matches the year detail page chart data" do
    get "/api/v1/backtest/1966", params: { fee: 1 }
    series = response.parsed_body["series"]

    get year_detail_path(1966, fee: 1)
    assert_response :success
    chart_json = css_select("[data-chart-data-value]").first["data-chart-data-value"]
    assert_equal series, JSON.parse(chart_json)
  end

  test "unknown start year is a 404 JSON error" do
    get "/api/v1/backtest/1800"
    assert_response :not_found
    assert response.parsed_body["error"].present?
    assert_match(/no-store|no-cache/, response.headers["Cache-Control"])
  end

  test "start year before the scenario has data is a 404" do
    get "/api/v1/backtest/1960", params: { scenario: "nasdaq" }
    assert_response :not_found
  end
end

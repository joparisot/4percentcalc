require "test_helper"

class CalculatorControllerTest < ActionDispatch::IntegrationTest
  test "index renders with default values" do
    get root_path
    assert_response :success
    assert_select "h1", "The 4% Rule Calculator"
    assert_select "input[name='initial_amount'][value='1000000']"
  end

  test "index accepts custom parameters" do
    get root_path, params: { initial_amount: 500_000, withdrawal_rate: 5.0 }
    assert_response :success
    assert_select "input[name='initial_amount'][value='500000']"
  end

  test "methodology page renders" do
    get methodology_path
    assert_response :success
    assert_select "h1", "Methodology"
    assert_select "h2", "How It Works"
    assert_select "h2", "Data Sources"
    assert_select "h2", "Assumptions"
  end

  test "calculate returns turbo stream" do
    post calculate_path, params: { initial_amount: 1_000_000, withdrawal_rate: 4.0 },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_match "turbo-stream", response.body
  end

  test "year_detail renders HTML page with chart" do
    get year_detail_path(year: 1990), params: { initial_amount: 1_000_000, withdrawal_rate: 4.0 }
    assert_response :success
    assert_select "h2", /Portfolio Value: Started in 1990/
    assert_select "[data-controller='chart']"
    assert_select "a[href*='#{root_path}']", text: /Back to Calculator/
  end
end

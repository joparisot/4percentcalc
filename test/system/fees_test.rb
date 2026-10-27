require "test_helper"

class FeesTest < ActionDispatch::SystemTestCase
  test "picking an annual fee recalculates and carries into year-detail links" do
    visit root_path
    assert_no_selector "a[href*='fee=']"

    select "1%", from: "fee-select"
    assert_selector "a[href*='/year_detail/'][href*='fee=1']", wait: 3
    assert_equal "1", find("#fee-select").value
  end
end

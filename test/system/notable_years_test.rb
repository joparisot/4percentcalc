require "test_helper"

class NotableYearsTest < ActionDispatch::SystemTestCase
  test "homepage notable years link to their year pages" do
    YearSummary.featured_years.each do |year|
      visit root_path
      within("nav[aria-labelledby='notable-years-heading']") { click_link year.to_s }

      assert_current_path year_detail_path(year)
      assert_selector "h1", text: "Retiring in #{year}"
    end
  end
end

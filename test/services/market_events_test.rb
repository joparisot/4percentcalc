require "test_helper"

class MarketEventsTest < ActiveSupport::TestCase
  test "events are labelled, in order, and fall within the historical data" do
    years = Calculator.new.available_years
    events = MarketEvents.all

    assert_operator events.size, :>=, 3
    assert_equal events.map { |e| e[:year] }.sort, events.map { |e| e[:year] }
    events.each do |event|
      assert_includes years, event[:year]
      assert event[:label].present?
    end
  end

  test "each event year was a losing year for stocks" do
    data_by_year = Calculator.new.data_by_year
    MarketEvents.all.each do |event|
      next if event[:year] == 2020 # COVID crash recovered within the year
      assert_operator data_by_year[event[:year]]["sp500_return"], :<, 0, "#{event[:year]} #{event[:label]}"
    end
  end
end

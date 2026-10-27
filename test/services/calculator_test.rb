require "test_helper"

class CalculatorTest < ActiveSupport::TestCase
  def setup
    @calculator = Calculator.new
  end

  test "loads historical data" do
    years = @calculator.available_years
    assert years.any?, "Should have available years"
    assert years.include?(1927), "Should include 1927"
    assert years.include?(2023), "Should include 2023"
  end

  test "backtest returns milestones" do
    result = @calculator.backtest(
      initial_amount: 1_000_000,
      withdrawal_rate: 4,
      starting_year: 1980
    )

    assert_equal 1980, result[:starting_year]
    assert result[:milestones].key?(10), "Should have 10-year milestone"
    assert result[:milestones].key?(20), "Should have 20-year milestone"
    assert result[:milestones].key?(30), "Should have 30-year milestone"
  end

  test "backtest with high withdrawal rate depletes portfolio" do
    result = @calculator.backtest(
      initial_amount: 1_000_000,
      withdrawal_rate: 50,
      starting_year: 1980
    )

    assert result[:depleted_at].present?, "Should be depleted with 50% withdrawal"
    assert result[:depleted_at] < 10, "Should deplete within 10 years"
  end

  test "backtest with low withdrawal rate grows portfolio" do
    result = @calculator.backtest(
      initial_amount: 1_000_000,
      withdrawal_rate: 2,
      starting_year: 1980
    )

    assert_nil result[:depleted_at], "Should not be depleted with 2% withdrawal"
    assert result[:milestones][10] > 1_000_000, "Portfolio should grow with 2% withdrawal"
  end

  test "backtest_all returns results for all starting years" do
    results = @calculator.backtest_all(
      initial_amount: 1_000_000,
      withdrawal_rate: 4
    )

    assert results.any?, "Should have results"
    assert results.all? { |r| r[:starting_year].present? }, "All results should have starting year"
  end

  test "summary_stats calculates success rate" do
    results = @calculator.backtest_all(
      initial_amount: 1_000_000,
      withdrawal_rate: 4
    )

    stats = @calculator.summary_stats(results, horizon: 30)

    assert stats[:success_rate].present?, "Should have success rate"
    assert stats[:success_rate] >= 0 && stats[:success_rate] <= 100, "Success rate should be percentage"
    assert stats[:worst_year].present?, "Should identify worst year"
    assert stats[:best_year].present?, "Should identify best year"
  end

  test "4% withdrawal rate has high success rate historically" do
    results = @calculator.backtest_all(
      initial_amount: 1_000_000,
      withdrawal_rate: 4
    )

    stats = @calculator.summary_stats(results, horizon: 30)

    # Historical 4% rule should have ~95%+ success rate over 30 years
    assert stats[:success_rate] > 80, "4% rule should have high historical success rate"
  end

  test "required portfolio divides spending by the withdrawal rate" do
    assert_equal 2_000_000, Calculator.required_portfolio(annual_spending: 80_000, withdrawal_rate: 4.0)
    assert_equal 1_000_000, Calculator.required_portfolio(annual_spending: 40_000, withdrawal_rate: 4)
    assert_equal 1_000_000, Calculator.required_portfolio(annual_spending: 50_000, withdrawal_rate: 5.0)
  end

  test "required portfolio rounds to the nearest dollar" do
    assert_equal 2_285_714, Calculator.required_portfolio(annual_spending: 80_000, withdrawal_rate: 3.5)
    assert_equal 1_666_667, Calculator.required_portfolio(annual_spending: 50_000, withdrawal_rate: 3.0)
    assert_equal 888_889, Calculator.required_portfolio(annual_spending: 40_000, withdrawal_rate: 4.5)
  end
end

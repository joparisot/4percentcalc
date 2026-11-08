require "test_helper"

class CalculatorTest < ActiveSupport::TestCase
  def setup
    @calculator = Calculator.new
  end

  test "loads historical data" do
    years = @calculator.available_years
    assert years.any?, "Should have available years"
    assert_equal 1926, years.first
    assert_equal 2025, years.last
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

  test "each data year holds that calendar year's return" do
    # Jan 1929 to Jan 1930 (the Great Crash year) lost money; Jan 1928 to Jan 1929 was a +40% boom.
    assert_operator @calculator.data_by_year[1929]["sp500_return"], :<, 0
    assert_operator @calculator.data_by_year[1928]["sp500_return"], :>, 0.4
    assert_operator @calculator.data_by_year[1931]["sp500_return"], :<, -0.4
  end

  test "a 1929 retiree's first year applies the 1929 return" do
    result = @calculator.backtest(initial_amount: 1_000_000, withdrawal_rate: 4, starting_year: 1929)
    assert_equal 24, result[:depleted_at]
  end

  test "start years cover every year with at least 10 years of data" do
    years = @calculator.backtest_all(initial_amount: 1_000_000, withdrawal_rate: 4).map { |r| r[:starting_year] }
    assert_equal 1926, years.first
    assert_equal @calculator.available_years.last - 9, years.last
  end

  test "summary_stats counts a portfolio that funded every year of the horizon as a success" do
    results = [
      { starting_year: 1, milestones: { 30 => 50_000 }, depleted_at: 30 },
      { starting_year: 2, milestones: { 30 => 0 }, depleted_at: 25 },
      { starting_year: 3, milestones: { 30 => 0 }, depleted_at: 20 },
      { starting_year: 4, milestones: { 30 => 2_000_000 }, depleted_at: nil }
    ]
    stats = @calculator.summary_stats(results, horizon: 30)
    assert_equal 50.0, stats[:success_rate]
    assert_equal 3, stats[:worst_year], "earliest depletion breaks ties between depleted years"
    assert_equal 4, stats[:best_year]
  end

  test "an annual fee is charged on the balance after each year's return" do
    base = @calculator.backtest(initial_amount: 1_000_000, withdrawal_rate: 4, starting_year: 1990)
    assert_equal base, @calculator.backtest(initial_amount: 1_000_000, withdrawal_rate: 4, starting_year: 1990, fee: 0)

    no_withdrawals = @calculator.backtest(initial_amount: 1_000_000, withdrawal_rate: 0, starting_year: 1990)
    with_fee = @calculator.backtest(initial_amount: 1_000_000, withdrawal_rate: 0, starting_year: 1990, fee: 1)
    assert_in_delta 0.99**10, with_fee[:milestones][10].fdiv(no_withdrawals[:milestones][10]), 1e-5
  end

  test "fees lower the success rate" do
    rate = ->(fee) { @calculator.summary_stats(@calculator.backtest_all(initial_amount: 1_000_000, withdrawal_rate: 4, fee: fee), horizon: 30)[:success_rate] }
    assert_operator rate.call(1), :<, rate.call(0)
  end


  test "every data year has a bond return" do
    assert @calculator.data_by_year.values.all? { |d| d["bond_return"].is_a?(Numeric) }
  end

  test "stock allocation blends S&P 500 and bond returns" do
    year = @calculator.data_by_year[2008]
    assert_in_delta year["sp500_return"], Scenario.find("sp500").annual_return(year), 1e-9
    assert_in_delta year["bond_return"], Scenario.find("bonds").annual_return(year), 1e-9
    assert_in_delta (year["sp500_return"] + year["bond_return"]) / 2, Scenario.find("sp50").annual_return(year), 1e-9
  end

  test "default backtest is 100% stocks" do
    default = @calculator.backtest(initial_amount: 1_000_000, withdrawal_rate: 4, starting_year: 1966)
    stocks = @calculator.backtest(initial_amount: 1_000_000, withdrawal_rate: 4, starting_year: 1966, scenario: Scenario.find("sp500"))
    assert_equal stocks, default
  end

  test "trinity mixes at 4% over 30 years" do
    rates = Scenario::ALL.select(&:trinity?).index_by(&:key).transform_values do |scenario|
      results = @calculator.backtest_all(initial_amount: 1_000_000, withdrawal_rate: 4, scenario: scenario)
      @calculator.summary_stats(results, horizon: 30)[:success_rate]
    end
    assert_equal 94.4, rates["sp500"]
    assert rates["sp50"] > rates["bonds"], "A 50/50 mix should beat all bonds"
    assert rates["bonds"] < 50, "All bonds should fail most 30-year retirements at 4%"
  end

  test "nasdaq backtest for a 2000 start runs out of money" do
    result = @calculator.backtest(initial_amount: 1_000_000, withdrawal_rate: 4.0, starting_year: 2000, scenario: Scenario.find("nasdaq"))
    assert result[:depleted_at]
    assert_operator result[:depleted_at], :<, 15
    assert_operator result[:milestones][10], :>, 100_000
    assert_operator result[:milestones][10], :<, 200_000
  end

  test "nasdaq backtests start in 1972" do
    results = @calculator.backtest_all(initial_amount: 1_000_000, withdrawal_rate: 4.0, scenario: Scenario.find("nasdaq"))
    assert_equal 1972, results.first[:starting_year]
  end

  test "scenario annual_return is nil without data" do
    assert_nil Scenario.find("nasdaq").annual_return({ "year" => 1950, "sp500_return" => 0.1, "bond_return" => 0.02 })
  end

  test "scenario from_param accepts keys and legacy allocations" do
    assert_equal "sp75", Scenario.from_param("75").key
    assert_equal "nasdaq", Scenario.from_param("nasdaq").key
    assert_nil Scenario.from_param("garbage")
    assert_nil Scenario.from_param(nil)
  end

  test "max_withdrawal_rate finds the highest rate that lasts the horizon" do
    assert_includes 3.7..3.9, @calculator.max_withdrawal_rate(starting_year: 1966)
    assert_operator @calculator.max_withdrawal_rate(starting_year: 1982), :>, 8
  end

  test "max_withdrawal_rate is nil without enough years of data" do
    assert_nil @calculator.max_withdrawal_rate(starting_year: 2000)
  end

  test "cape lookups" do
    assert_in_delta 24.06, @calculator.cape(1966), 0.01
    assert_nil @calculator.cape(1800)
    assert_equal 2026, @calculator.latest_cape[:year]
    assert_equal "2026-01", @calculator.latest_cape[:as_of]
  end
end

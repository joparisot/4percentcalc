class CalculatorController < ApplicationController
  FAQ_RATES = [3.0, 3.5, 4.0].freeze
  FAQ_EXAMPLE_SPENDING = 80_000

  def index
    run_scenario
    @notable_years = YearSummary.notes.slice(*YearSummary.featured_years)
    @faq = build_faq_data(@calculator)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def calculate
    run_scenario

    respond_to do |format|
      format.turbo_stream
    end
  end

  def year_detail
    @starting_year = params[:year].to_i
    @initial_amount = params[:initial_amount]&.to_i || 1_000_000
    @withdrawal_rate = params[:withdrawal_rate]&.to_f || 4.0

    calculator = Calculator.new
    years = calculator.available_years
    raise ActionController::RoutingError, "No data for #{params[:year]}" unless years.include?(@starting_year)

    @detail = calculator.backtest(
      initial_amount: @initial_amount,
      withdrawal_rate: @withdrawal_rate,
      starting_year: @starting_year
    )
    all_results = calculator.backtest_all(
      initial_amount: @initial_amount,
      withdrawal_rate: @withdrawal_rate
    )
    stats = calculator.summary_stats(all_results, horizon: 30)
    rank = { stats&.dig(:worst_year) => :worst, stats&.dig(:best_year) => :best }[@starting_year]

    @summary = YearSummary.new(
      result: @detail,
      initial_amount: @initial_amount,
      withdrawal_rate: @withdrawal_rate,
      market_data: calculator.data_by_year,
      rank: rank
    )
    @scenario_params = request.query_parameters.slice("initial_amount", "withdrawal_rate")
    @previous_year = years.select { |y| y < @starting_year }.max
    @next_year = years.select { |y| y > @starting_year }.min
    if @summary.depleted?
      @other_depleted_years = all_results.filter_map { |r| r[:starting_year] if r[:depleted_at] } - [@starting_year]
    end

    # Build year-by-year data for chart
    @chart_data = build_chart_data(@starting_year, @initial_amount, @withdrawal_rate)

    respond_to do |format|
      format.html
    end
  end

  def methodology
  end

  private

  # Spending mode is chosen by the mode toggle, or by an annual_spending param in a shared link.
  def run_scenario
    @withdrawal_rate = params[:withdrawal_rate]&.to_f || 4.0
    @horizon = (params[:horizon]&.to_i || 30)
    @mode = params[:mode].presence_in(%w[portfolio spending]) ||
      (params[:annual_spending].present? ? "spending" : "portfolio")

    if @mode == "spending"
      @withdrawal_rate = @withdrawal_rate.clamp(1.0, 12.0)
      @annual_spending = params[:annual_spending]&.to_i || 40_000
      @initial_amount = Calculator.required_portfolio(annual_spending: @annual_spending, withdrawal_rate: @withdrawal_rate)
    else
      @initial_amount = params[:initial_amount]&.to_i || 1_000_000
      @annual_spending = (@initial_amount * @withdrawal_rate / 100).round
    end

    @calculator = Calculator.new
    results = @calculator.backtest_all(
      initial_amount: @initial_amount,
      withdrawal_rate: @withdrawal_rate
    )
    @results = results.reverse
    @stats = @calculator.summary_stats(results, horizon: 30)
    @horizon_chart_data = build_horizon_chart_data(@results)
  end

  # Figures quoted in the homepage FAQ, always for a $1M portfolio regardless of the
  # visitor's scenario so the page copy and FAQPage JSON-LD stay stable.
  def build_faq_data(calculator)
    by_rate = FAQ_RATES.index_with do |rate|
      results = calculator.backtest_all(initial_amount: 1_000_000, withdrawal_rate: rate)
      stats = calculator.summary_stats(results, horizon: 30)
      stats.merge(
        failed_years: results.select { |r| r[:milestones][30] && r[:depleted_at] && r[:depleted_at] < 30 }.map { |r| r[:starting_year] },
        later_failed_years: results.select { |r| r[:depleted_at] && r[:depleted_at] >= 30 }.map { |r| r[:starting_year] }
      )
    end
    years = calculator.available_years

    {
      by_rate: by_rate,
      example_spending: FAQ_EXAMPLE_SPENDING,
      example_portfolio: Calculator.required_portfolio(annual_spending: FAQ_EXAMPLE_SPENDING, withdrawal_rate: 4.0),
      first_year: years.first,
      last_year: years.last
    }
  end

  def build_horizon_chart_data(results)
    # Build data for each horizon: { 10 => [{year: 1926, value: 123}, ...], 20 => [...], ... }
    horizons = [10, 20, 30, 40, 50]
    horizons.each_with_object({}) do |horizon, data|
      data[horizon] = results.map do |result|
        value = result[:milestones][horizon]
        next nil if value.nil?
        { year: result[:starting_year], value: value }
      end.compact
    end
  end

  def build_chart_data(starting_year, initial_amount, withdrawal_rate)
    data = JSON.parse(File.read(Rails.root.join('lib/data/shiller_data.json')))
    data_by_year = data.index_by { |d| d["year"] }

    portfolio = initial_amount.to_f
    annual_withdrawal = initial_amount.to_f * (withdrawal_rate.to_f / 100)

    chart_points = [{ year: 0, value: portfolio.round(0) }]

    (0...50).each do |year_offset|
      current_year = starting_year + year_offset
      year_data = data_by_year[current_year]

      break unless year_data

      portfolio -= annual_withdrawal
      break if portfolio <= 0

      portfolio *= (1 + year_data["sp500_return"])
      chart_points << { year: year_offset + 1, value: portfolio.round(0) }

      annual_withdrawal *= (1 + year_data["inflation"])
    end

    # If portfolio hit zero, add final point
    if portfolio <= 0
      chart_points << { year: chart_points.last[:year] + 1, value: 0 }
    end

    chart_points
  end
end

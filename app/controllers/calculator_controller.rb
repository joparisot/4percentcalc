class CalculatorController < ApplicationController
  def index
    @initial_amount = params[:initial_amount]&.to_i || 1_000_000
    @withdrawal_rate = params[:withdrawal_rate]&.to_f || 4.0
    @horizon = (params[:horizon]&.to_i || 30)

    calculator = Calculator.new
    results = calculator.backtest_all(
      initial_amount: @initial_amount,
      withdrawal_rate: @withdrawal_rate
    )
    @results = results.reverse
    @stats = calculator.summary_stats(results, horizon: 30)
    @horizon_chart_data = build_horizon_chart_data(@results)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def calculate
    @initial_amount = params[:initial_amount]&.to_i || 1_000_000
    @withdrawal_rate = params[:withdrawal_rate]&.to_f || 4.0
    @horizon = (params[:horizon]&.to_i || 30)

    calculator = Calculator.new
    results = calculator.backtest_all(
      initial_amount: @initial_amount,
      withdrawal_rate: @withdrawal_rate
    )
    @results = results.reverse
    @stats = calculator.summary_stats(results, horizon: 30)
    @horizon_chart_data = build_horizon_chart_data(@results)

    respond_to do |format|
      format.turbo_stream
    end
  end

  def year_detail
    @starting_year = params[:year].to_i
    @initial_amount = params[:initial_amount]&.to_i || 1_000_000
    @withdrawal_rate = params[:withdrawal_rate]&.to_f || 4.0

    calculator = Calculator.new
    @detail = calculator.backtest(
      initial_amount: @initial_amount,
      withdrawal_rate: @withdrawal_rate,
      starting_year: @starting_year
    )

    # Build year-by-year data for chart
    @chart_data = build_chart_data(@starting_year, @initial_amount, @withdrawal_rate)

    respond_to do |format|
      format.html
    end
  end

  def methodology
  end

  private

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

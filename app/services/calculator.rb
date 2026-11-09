class Calculator
  MILESTONES = [10, 20, 30, 40, 50].freeze
  attr_reader :data, :data_by_year, :nasdaq_source

  # Portfolio needed so that year one's withdrawal covers annual_spending.
  def self.required_portfolio(annual_spending:, withdrawal_rate:)
    (annual_spending.to_f * 100 / withdrawal_rate.to_f).round
  end

  def initialize
    @data = load_data
    @data_by_year = @data.index_by { |d| d["year"] }
  end

  # Returns all available starting years
  def available_years
    @data.map { |d| d["year"] }.sort
  end

  # Run backtest for a single starting year
  # Returns hash with portfolio values at milestones
  # Trinity scenarios hold stocks and 10-year Treasuries, rebalanced every year; the Nasdaq scenario is 100% Nasdaq Composite.
  def backtest(initial_amount:, withdrawal_rate:, starting_year:, scenario: Scenario.default, fee: 0)
    portfolio = initial_amount.to_f
    annual_withdrawal = initial_amount.to_f * (withdrawal_rate.to_f / 100)

    results = { starting_year: starting_year, scenario: scenario.key, milestones: {} }
    depleted_at = nil

    (0...50).each do |year_offset|
      current_year = starting_year + year_offset
      year_data = @data_by_year[current_year]

      # If we don't have data for this year, stop
      break unless year_data

      scenario_return = scenario.annual_return(year_data)
      break if scenario_return.nil?

      # Withdraw at start of year
      portfolio -= annual_withdrawal

      if portfolio <= 0
        depleted_at = year_offset
        portfolio = 0
        # Record 0 for all remaining milestones
        MILESTONES.each do |m|
          results[:milestones][m] = 0 if m >= year_offset && !results[:milestones].key?(m)
        end
        break
      end

      # Apply market return for this year
      portfolio *= (1 + scenario_return)
      # Annual fee (% of assets), charged on the end-of-year balance
      portfolio *= (1 - fee.to_f / 100)

      # Record milestone if applicable
      if MILESTONES.include?(year_offset + 1)
        results[:milestones][year_offset + 1] = portfolio.round(0)
      end

      # Adjust next year's withdrawal for inflation
      annual_withdrawal *= (1 + year_data["inflation"])
    end

    results[:depleted_at] = depleted_at
    results[:final_portfolio] = portfolio.round(0)
    results
  end

  # Run backtest for all starting years
  def backtest_all(initial_amount:, withdrawal_rate:, scenario: Scenario.default, fee: 0)
    # Only test years where we have at least 10 years of data
    max_start_year = available_years.last - (MILESTONES.min - 1)

    available_years.select { |y| y <= max_start_year && y >= (scenario.first_year || y) }.map do |year|
      backtest(
        initial_amount: initial_amount,
        withdrawal_rate: withdrawal_rate,
        starting_year: year,
        scenario: scenario,
        fee: fee
      )
    end
  end

  # Year-by-year portfolio values for one starting year; year 0 is the starting balance.
  def series(initial_amount:, withdrawal_rate:, starting_year:, fee: 0, scenario: Scenario.default)
    portfolio = initial_amount.to_f
    annual_withdrawal = initial_amount.to_f * (withdrawal_rate.to_f / 100)

    chart_points = [{ year: 0, value: portfolio.round(0) }]

    (0...50).each do |year_offset|
      year_data = @data_by_year[starting_year + year_offset]

      break unless year_data

      scenario_return = scenario.annual_return(year_data)
      break if scenario_return.nil?

      portfolio -= annual_withdrawal
      break if portfolio <= 0

      portfolio *= (1 + scenario_return)
      portfolio *= (1 - fee.to_f / 100)
      chart_points << { year: year_offset + 1, value: portfolio.round(0) }

      annual_withdrawal *= (1 + year_data["inflation"])
    end

    # If portfolio hit zero, add final point
    if portfolio <= 0
      chart_points << { year: chart_points.last[:year] + 1, value: 0 }
    end

    chart_points
  end

  # 30-year success rate for $1M at 4%, keyed by annual fee percentage.
  def fee_example(fees: [0, 1])
    fees.to_h do |fee|
      results = backtest_all(initial_amount: 1_000_000, withdrawal_rate: 4.0, fee: fee)
      [fee, summary_stats(results, horizon: 30)[:success_rate]]
    end
  end

  # Number of return years available from a start year, inclusive.
  def years_of_data(starting_year)
    available_years.last - starting_year + 1
  end

  # Highest first-year withdrawal rate (to 0.01%) that lasts `horizon` years; nil without that much history.
  def max_withdrawal_rate(starting_year:, horizon: 30, scenario: Scenario.default, fee: 0)
    options = { initial_amount: 1_000_000, starting_year: starting_year, scenario: scenario, fee: fee }
    return nil if years_of_data(starting_year) < horizon

    low = 0.5
    high = 20.0
    25.times do
      mid = (low + high) / 2
      depleted_at = backtest(**options, withdrawal_rate: mid)[:depleted_at]
      if depleted_at.nil? || depleted_at >= horizon
        low = mid
      else
        high = mid
      end
    end
    low.round(2)
  end

  def cape(year)
    @cape_by_year[year.to_s]
  end

  def latest_cape
    year = @cape_by_year.keys.map(&:to_i).max
    { year: year, value: @cape_by_year[year.to_s], as_of: @cape_as_of }
  end

  # Calculate summary statistics
  def summary_stats(results, horizon: 30)
    completed_results = results.select { |r| r[:milestones][horizon] }

    return nil if completed_results.empty?

    # depleted_at is the number of full withdrawals made, so depleted_at == horizon still lasted the horizon.
    survived = completed_results.reject { |r| r[:depleted_at] && r[:depleted_at] < horizon }
    final_values = completed_results.map { |r| r[:milestones][horizon] }.compact.sort

    {
      success_rate: (survived.count.to_f / completed_results.count * 100).round(1),
      total_periods: completed_results.count,
      worst_year: completed_results.min_by { |r| [r[:milestones][horizon] || 0, r[:depleted_at] || Float::INFINITY] }&.dig(:starting_year),
      best_year: completed_results.max_by { |r| r[:milestones][horizon] || 0 }&.dig(:starting_year),
      median_final_value: final_values[final_values.length / 2]
    }
  end

  private

  def load_data
    json_path = Rails.root.join('lib/data/shiller_data.json')
    nasdaq_file = JSON.parse(File.read(Rails.root.join('lib/data/nasdaq_returns.json')))
    @nasdaq_source = nasdaq_file["source"]
    valuations = JSON.parse(File.read(Rails.root.join('lib/data/valuations.json')))
    @cape_by_year = valuations["cape"]
    @cape_as_of = valuations["as_of"]
    nasdaq = nasdaq_file["returns"]
    JSON.parse(File.read(json_path)).each { |year_data| year_data["nasdaq_return"] = nasdaq[year_data["year"].to_s] }
  end
end

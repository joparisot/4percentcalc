class Calculator
  MILESTONES = [10, 20, 30, 40, 50].freeze

  attr_reader :data_by_year

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
  def backtest(initial_amount:, withdrawal_rate:, starting_year:, fee: 0)
    portfolio = initial_amount.to_f
    annual_withdrawal = initial_amount.to_f * (withdrawal_rate.to_f / 100)

    results = { starting_year: starting_year, milestones: {} }
    depleted_at = nil

    (0...50).each do |year_offset|
      current_year = starting_year + year_offset
      year_data = @data_by_year[current_year]

      # If we don't have data for this year, stop
      break unless year_data

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
      portfolio *= (1 + year_data["sp500_return"])
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
  def backtest_all(initial_amount:, withdrawal_rate:, fee: 0)
    # Only test years where we have at least 10 years of data
    max_start_year = available_years.last - (MILESTONES.min - 1)

    available_years.select { |y| y <= max_start_year }.map do |year|
      backtest(
        initial_amount: initial_amount,
        withdrawal_rate: withdrawal_rate,
        starting_year: year,
        fee: fee
      )
    end
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
    JSON.parse(File.read(json_path))
  end
end

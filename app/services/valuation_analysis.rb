class ValuationAnalysis
  HORIZON = 30
  THRESHOLD = 4.0
  IN_PROGRESS_MIN_YEARS = 20
  RANGES = [[nil, 15], [15, 20], [20, 25], [25, nil]].freeze

  def self.current
    @current ||= new(Calculator.new)
  end

  def initialize(calculator)
    @calculator = calculator
  end

  def points
    @points ||= @calculator.available_years.filter_map do |year|
      cape = @calculator.cape(year)
      next unless cape

      max_swr = @calculator.max_withdrawal_rate(starting_year: year, horizon: HORIZON)
      next unless max_swr

      { year: year, cape: cape, earnings_yield: (100.0 / cape).round(1), max_swr: max_swr }
    end.sort_by { |point| point[:year] }
  end

  def in_progress_points
    @in_progress_points ||= @calculator.available_years.filter_map do |year|
      cape = @calculator.cape(year)
      elapsed = @calculator.years_of_data(year)
      next unless cape && elapsed.between?(IN_PROGRESS_MIN_YEARS, HORIZON - 1)

      four_percent = @calculator.backtest(initial_amount: 1_000_000, withdrawal_rate: THRESHOLD, starting_year: year)
      {
        year: year,
        cape: cape,
        earnings_yield: (100.0 / cape).round(1),
        years_elapsed: elapsed,
        max_swr_so_far: @calculator.max_withdrawal_rate(starting_year: year, horizon: elapsed),
        four_percent_alive: four_percent[:depleted_at].nil?
      }
    end.sort_by { |point| point[:year] }
  end

  def today
    latest = @calculator.latest_cape
    { year: latest[:year], cape: latest[:value], as_of: latest[:as_of] }
  end

  def highest_start
    points.max_by { |point| point[:cape] }
  end

  def percentile(cape)
    (points.count { |point| point[:cape] < cape } * 100.0 / points.size).round
  end

  def buckets
    RANGES.filter_map do |low, high|
      members = points.select { |p| (low.nil? || p[:cape] >= low) && (high.nil? || p[:cape] < high) }
      next if members.empty?

      rates = members.map { |p| p[:max_swr] }.sort
      mid = rates.size / 2
      {
        label: bucket_label(low, high),
        count: members.size,
        survived_count: members.count { |p| p[:max_swr] >= THRESHOLD },
        median_swr: rates.size.odd? ? rates[mid] : ((rates[mid - 1] + rates[mid]) / 2).round(2),
        worst: members.min_by { |p| p[:max_swr] }
      }
    end
  end

  def correlation
    xs = points.map { |p| p[:cape] }
    ys = points.map { |p| p[:max_swr] }
    mean_x = xs.sum / xs.size
    mean_y = ys.sum / ys.size
    covariance = xs.zip(ys).sum { |x, y| (x - mean_x) * (y - mean_y) }
    spread = Math.sqrt(xs.sum { |x| (x - mean_x)**2 } * ys.sum { |y| (y - mean_y)**2 })
    (covariance / spread).round(2)
  end

  private

  def bucket_label(low, high)
    return "Under #{high}" if low.nil?
    return "Over #{low}" if high.nil?

    "#{low} to #{high}"
  end
end

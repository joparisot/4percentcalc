class Scenario
  attr_reader :key, :label, :color, :stock_allocation, :first_year

  def initialize(key:, label:, color:, stock_allocation:, first_year: nil)
    @key = key
    @label = label
    @color = color
    @stock_allocation = stock_allocation
    @first_year = first_year
  end

  ALL = [
    new(key: "sp500", label: "100% S&P 500", color: "#7C3AED", stock_allocation: 100),
    new(key: "sp75", label: "75/25 stocks/bonds", color: "#2563EB", stock_allocation: 75),
    new(key: "sp50", label: "50/50 stocks/bonds", color: "#0D9488", stock_allocation: 50),
    new(key: "sp25", label: "25/75 stocks/bonds", color: "#F59E0B", stock_allocation: 25),
    new(key: "bonds", label: "100% bonds", color: "#6B7280", stock_allocation: 0),
    new(key: "nasdaq", label: "100% Nasdaq Composite", color: "#EC4899", stock_allocation: nil, first_year: 1972)
  ].freeze

  def self.find(key)
    ALL.find { |scenario| scenario.key == key.to_s }
  end

  def self.default = find("sp500")

  def self.default_comparison = find("sp50")

  # Accepts a scenario key ("sp75") or a legacy stock_allocation percentage ("75").
  def self.from_param(value)
    value = value.to_s
    return nil if value.blank?

    find(value) || (ALL.find { |scenario| scenario.trinity? && scenario.stock_allocation.to_s == value })
  end

  def trinity? = !stock_allocation.nil?

  def nasdaq? = key == "nasdaq"

  # Nil when the scenario has no data for that year.
  def annual_return(year_data)
    return year_data["nasdaq_return"] unless trinity?

    stocks = stock_allocation / 100.0
    stocks * year_data["sp500_return"] + (1 - stocks) * year_data["bond_return"]
  end
end

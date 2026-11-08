module Api
  module V1
    class DataController < BaseController
      SHILLER_SOURCE = "Robert Shiller, Yale University, http://www.econ.yale.edu/~shiller/data.htm (S&P 500 total return, 10-year Treasury return, CPI inflation)".freeze

      def show
        calculator = Calculator.new

        render_cached(
          years: calculator.data.map { |row| row.slice("year", "sp500_return", "bond_return", "inflation", "nasdaq_return") },
          scenarios: Scenario::ALL.map do |scenario|
            { key: scenario.key, label: scenario.label, stock_allocation: scenario.stock_allocation, first_year: scenario.first_year || calculator.available_years.first }
          end,
          sources: { shiller: SHILLER_SOURCE, nasdaq: calculator.nasdaq_source },
          meta: meta_links
        )
      end
    end
  end
end

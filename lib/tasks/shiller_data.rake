require 'roo'
require 'json'

namespace :shiller do
  desc "Parse Shiller Excel data and generate JSON"
  task :parse => :environment do
    xlsx = Roo::Spreadsheet.open(Rails.root.join('lib/data/ie_data.xls').to_s, extension: :xls)
    sheet = xlsx.sheet('Data')

    # Data structure (starting row 9):
    # Col 1: Date (YYYY.MM format, e.g., 1871.01)
    # Col 2: S&P Comp Price
    # Col 3: Dividend
    # Col 4: Earnings
    # Col 5: CPI

    annual_data = {}

    # Iterate through rows (data starts at row 9)
    (9..sheet.last_row).each do |row_num|
      date_val = sheet.cell(row_num, 1)
      next unless date_val.is_a?(Numeric)

      year = date_val.to_i
      month = ((date_val - year) * 100).round

      next if year < 1926 # Start from 1926
      next unless month == 1 # Only January data for annual snapshots

      price = sheet.cell(row_num, 2)&.to_f
      dividend = sheet.cell(row_num, 3)&.to_f
      cpi = sheet.cell(row_num, 5)&.to_f

      next unless price && price > 0 && cpi && cpi > 0

      annual_data[year] = {
        price: price.round(2),
        dividend: dividend.round(2),
        cpi: cpi.round(2)
      }
    end

    # Calculate returns and inflation rates
    years = annual_data.keys.sort
    result = []

    years.each_with_index do |year, idx|
      next if idx == 0 # Need previous year for return calculation

      prev_year = years[idx - 1]
      next unless prev_year == year - 1 # Ensure consecutive years

      current = annual_data[year]
      previous = annual_data[prev_year]

      # Total return = (price_end - price_start + dividends) / price_start
      # Using current year's dividend as proxy for annual dividend
      price_return = (current[:price] - previous[:price]) / previous[:price]
      dividend_yield = current[:dividend] / previous[:price]
      total_return = price_return + dividend_yield

      # Inflation = (cpi_end - cpi_start) / cpi_start
      inflation = (current[:cpi] - previous[:cpi]) / previous[:cpi]

      # Label each return by the year it covers: Jan prev_year to Jan year.
      result << {
        year: prev_year,
        sp500_return: total_return.round(4),
        inflation: inflation.round(4)
      }
    end

    # Write to JSON file
    output_path = Rails.root.join('lib/data/shiller_data.json')
    File.write(output_path, JSON.pretty_generate(result))

    puts "Generated #{result.length} years of data (#{result.first[:year]}-#{result.last[:year]})"
    puts "Saved to #{output_path}"
  end
end

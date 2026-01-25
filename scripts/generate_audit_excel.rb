#!/usr/bin/env ruby
# Script to generate an Excel file with formulas for auditing the calculation logic

require 'json'
require 'caxlsx'

# Load the Shiller data
data_path = File.join(__dir__, '../lib/data/shiller_data.json')
data = JSON.parse(File.read(data_path))
data_by_year = data.each_with_object({}) { |d, h| h[d["year"]] = d }

# Parameters
INITIAL_AMOUNT = 1_000_000
WITHDRAWAL_RATE = 4.0

# Create output directory
output_dir = File.join(__dir__, '../tmp')
Dir.mkdir(output_dir) unless Dir.exist?(output_dir)

Axlsx::Package.new do |p|
  wb = p.workbook

  # === SHEET 1: Raw Data ===
  wb.add_worksheet(name: "Data") do |sheet|
    sheet.add_row ["Year", "S&P 500 Return", "Inflation Rate"], style: wb.styles.add_style(b: true, bg_color: "DDDDDD")
    data.sort_by { |d| d["year"] }.each do |d|
      sheet.add_row [d["year"], d["sp500_return"], d["inflation"]]
    end
  end

  # === SHEET 2: Single Year Calculation (with formulas) ===
  # This shows the step-by-step calculation for year 1966 (a famous bad year)
  starting_year = 1966

  wb.add_worksheet(name: "Calculation - #{starting_year}") do |sheet|
    bold = wb.styles.add_style(b: true)
    header = wb.styles.add_style(b: true, bg_color: "DDDDDD")
    currency = wb.styles.add_style(format_code: '$#,##0')
    percent = wb.styles.add_style(format_code: '0.00%')

    # Parameters section
    sheet.add_row ["PARAMETERS"], style: bold
    sheet.add_row ["Initial Amount", INITIAL_AMOUNT], style: [nil, currency]
    sheet.add_row ["Withdrawal Rate", WITHDRAWAL_RATE / 100], style: [nil, percent]
    sheet.add_row ["Starting Year", starting_year]
    sheet.add_row ["First Year Withdrawal", "=B2*B3"], style: [nil, currency]
    sheet.add_row []

    # Column headers for calculation
    sheet.add_row [
      "Year #",           # A
      "Calendar Year",    # B
      "Portfolio Start",  # C
      "Withdrawal",       # D
      "After Withdrawal", # E
      "S&P Return",       # F
      "Portfolio End",    # G
      "Inflation",        # H
      "Next Withdrawal"   # I
    ], style: header

    # Data rows with formulas
    # First row (Year 1) is special - uses initial values
    row_num = 8
    sheet.add_row [
      1,                                    # Year #
      starting_year,                        # Calendar Year
      "=B2",                                # Portfolio Start = Initial Amount
      "=B5",                                # Withdrawal = First Year Withdrawal
      "=C#{row_num}-D#{row_num}",           # After Withdrawal
      "=VLOOKUP(B#{row_num},Data!A:C,2,FALSE)", # S&P Return from Data sheet
      "=E#{row_num}*(1+F#{row_num})",       # Portfolio End
      "=VLOOKUP(B#{row_num},Data!A:C,3,FALSE)", # Inflation from Data sheet
      "=D#{row_num}*(1+H#{row_num})"        # Next Withdrawal
    ]

    # Subsequent rows reference the previous row
    (2..50).each do |year_num|
      row_num = 7 + year_num
      prev_row = row_num - 1
      calendar_year = starting_year + year_num - 1

      # Stop if we don't have data for this year
      break unless data_by_year[calendar_year]

      sheet.add_row [
        year_num,                               # Year #
        calendar_year,                          # Calendar Year
        "=G#{prev_row}",                        # Portfolio Start = Previous Portfolio End
        "=I#{prev_row}",                        # Withdrawal = Previous Next Withdrawal
        "=IF(C#{row_num}-D#{row_num}<0,0,C#{row_num}-D#{row_num})", # After Withdrawal (floor at 0)
        "=VLOOKUP(B#{row_num},Data!A:C,2,FALSE)", # S&P Return
        "=IF(E#{row_num}<=0,0,E#{row_num}*(1+F#{row_num}))", # Portfolio End
        "=VLOOKUP(B#{row_num},Data!A:C,3,FALSE)", # Inflation
        "=D#{row_num}*(1+H#{row_num})"          # Next Withdrawal
      ]
    end

    # Add milestone summary
    sheet.add_row []
    sheet.add_row ["MILESTONES"], style: bold
    sheet.add_row ["Year 10", "=G17"], style: [nil, currency]  # Row 8 + 9 = 17
    sheet.add_row ["Year 20", "=G27"], style: [nil, currency]  # Row 8 + 19 = 27
    sheet.add_row ["Year 30", "=G37"], style: [nil, currency]  # Row 8 + 29 = 37
    sheet.add_row ["Year 40", "=G47"], style: [nil, currency]  # Row 8 + 39 = 47
    sheet.add_row ["Year 50", "=G57"], style: [nil, currency]  # Row 8 + 49 = 57

    # Set column widths
    sheet.column_widths 8, 12, 15, 15, 15, 12, 15, 12, 15
  end

  # === SHEET 3: Results Table ===
  # Shows the summary for all starting years
  wb.add_worksheet(name: "Results Table") do |sheet|
    bold = wb.styles.add_style(b: true)
    header = wb.styles.add_style(b: true, bg_color: "DDDDDD")
    currency = wb.styles.add_style(format_code: '$#,##0')

    sheet.add_row ["PARAMETERS"], style: bold
    sheet.add_row ["Initial Amount", INITIAL_AMOUNT], style: [nil, currency]
    sheet.add_row ["Withdrawal Rate", "#{WITHDRAWAL_RATE}%"]
    sheet.add_row []

    sheet.add_row ["Starting Year", "Year 10", "Year 20", "Year 30", "Year 40", "Year 50", "Depleted?"], style: header

    # Calculate for all years (values, not formulas, for this summary)
    max_start_year = data.map { |d| d["year"] }.max - 10

    data.map { |d| d["year"] }.sort.select { |y| y <= max_start_year }.each do |sy|
      portfolio = INITIAL_AMOUNT.to_f
      annual_withdrawal = INITIAL_AMOUNT.to_f * (WITHDRAWAL_RATE / 100)
      milestones = {}
      depleted_at = nil

      (0...50).each do |year_offset|
        current_year = sy + year_offset
        year_data = data_by_year[current_year]

        break unless year_data

        portfolio -= annual_withdrawal

        if portfolio <= 0
          depleted_at = year_offset
          [10, 20, 30, 40, 50].each { |m| milestones[m] = 0 if m >= year_offset && !milestones.key?(m) }
          break
        end

        portfolio *= (1 + year_data["sp500_return"])
        milestones[year_offset + 1] = portfolio.round(0) if [10, 20, 30, 40, 50].include?(year_offset + 1)
        annual_withdrawal *= (1 + year_data["inflation"])
      end

      sheet.add_row [
        sy,
        milestones[10] || "N/A",
        milestones[20] || "N/A",
        milestones[30] || "N/A",
        milestones[40] || "N/A",
        milestones[50] || "N/A",
        depleted_at ? "Year #{depleted_at}" : "No"
      ]
    end

    sheet.column_widths 12, 12, 12, 12, 12, 12, 12
  end

  # Save the file
  output_path = File.join(output_dir, 'calculation_audit.xlsx')
  p.serialize(output_path)
  puts "✓ Created: #{output_path}"
  puts ""
  puts "Open in Excel and check:"
  puts "  1. 'Data' sheet - raw Shiller data"
  puts "  2. 'Calculation - 1966' sheet - step-by-step formulas for 1966"
  puts "  3. 'Results Table' sheet - all years summary"
end

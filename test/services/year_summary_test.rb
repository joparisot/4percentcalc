require "test_helper"

class YearSummaryTest < ActiveSupport::TestCase
  MARKET_DATA = {
    2000 => { "sp500_return" => 0.10, "inflation" => 0.10 },
    2001 => { "sp500_return" => -0.30, "inflation" => 0.10 },
    2002 => { "sp500_return" => 0.05, "inflation" => 0.10 }
  }.freeze

  def build(result, rank: nil, note: nil)
    YearSummary.new(result: result, initial_amount: 1_000_000, withdrawal_rate: 4.0,
                    market_data: MARKET_DATA, rank: rank, note: note)
  end

  test "depleted year reports when the money ran out" do
    summary = build({ starting_year: 2000, milestones: {}, depleted_at: 2, final_portfolio: 0 })

    assert summary.depleted?
    assert_equal "Ran out in year 3", summary.outcome_phrase
    assert_equal "Retiring in 2000: a 4% withdrawal ran out of money in year 3", summary.headline
    assert_equal "Retiring in 2000 on the 4% Rule: Ran out in year 3 | 4% Rule Calculator", summary.title
    assert_equal "Retiring in 2000 with $1M and a 4% inflation-adjusted withdrawal, the money ran out in year 3 (2002).", summary.description
    assert_includes summary.sentences, "Its worst year was the 12 months to January 2001, when the S&P 500 lost 30% including dividends."
    assert_includes summary.sentences, "Inflation had pushed the yearly withdrawal from $40K to $48K by then."
  end

  test "surviving year reports the ending balance" do
    summary = build({ starting_year: 2000, milestones: {}, depleted_at: nil, final_portfolio: 14_321_000 })

    refute summary.depleted?
    assert_equal "Ended with $14.3M", summary.outcome_phrase
    assert_equal "Retiring in 2000: $1M grew to $14.3M on a 4% withdrawal", summary.headline
    assert_equal "Retiring in 2000 with $1M and a 4% inflation-adjusted withdrawal, the portfolio was worth $14.3M after 3 years, as of the latest data.", summary.description
    assert_equal 2, summary.sentences.length
  end

  test "worst and best ranks change the headline" do
    result = { starting_year: 2000, milestones: {}, depleted_at: 2, final_portfolio: 0 }

    assert_equal "Retiring in 2000: the worst year to start the 4% rule", build(result, rank: :worst).headline
    assert_equal "Retiring in 2000: the best year to start the 4% rule", build(result, rank: :best).headline
  end

  test "historical context is appended when a note exists" do
    note = { "context" => "The dot-com bubble burst." }
    summary = build({ starting_year: 2000, milestones: {}, depleted_at: nil, final_portfolio: 500_000 }, note: note)

    assert_equal "Retiring in 2000: $1M fell to $500K on a 4% withdrawal", summary.headline
    assert_equal "The dot-com bubble burst.", summary.sentences.last
  end

  test "notes file has a label and one-sentence context for each year" do
    assert YearSummary.notes.size >= 20
    YearSummary.notes.each do |year, note|
      assert note["label"].present?, "#{year} needs a label"
      assert note["context"].end_with?("."), "#{year} context should end with a period"
      refute_match(/[.!?]\s+[A-Z]/, note["context"], "#{year} context should be one sentence")
    end
    assert_equal [1929, 1930, 1966, 1973, 1976, 2000, 2008], YearSummary.featured_years
  end
end

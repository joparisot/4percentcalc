# Builds the year-specific headline, title, and prose summary for /year_detail/:year
# from a Calculator#backtest result.
class YearSummary
  NOTES_PATH = Rails.root.join("lib/data/year_notes.yml")

  def self.notes
    @notes ||= YAML.load_file(NOTES_PATH).transform_keys(&:to_i).freeze
  end

  def self.featured_years
    notes.select { |_year, note| note["featured"] }.keys.sort
  end

  attr_reader :year

  # result:      hash returned by Calculator#backtest
  # market_data: { year => { "sp500_return" => Float, "inflation" => Float } }
  # rank:        :worst or :best when this start year is the worst/best on the homepage
  def initialize(result:, initial_amount:, withdrawal_rate:, market_data:, rank: nil, note: self.class.notes[result[:starting_year]])
    @result = result
    @year = result[:starting_year]
    @initial_amount = initial_amount
    @withdrawal_rate = withdrawal_rate
    @market_data = market_data
    @rank = rank
    @note = note
  end

  def depleted?
    !@result[:depleted_at].nil?
  end

  def headline
    "Retiring in #{year}: #{headline_outcome}"
  end

  def outcome_phrase
    if depleted?
      "Ran out in year #{depletion_year_number}"
    else
      "Ended with #{compact_currency(final_balance)}"
    end
  end

  def title
    "Retiring in #{year} on the #{rate_label} Rule: #{outcome_phrase} | 4% Rule Calculator"
  end

  def description
    sentences.first
  end

  def sentences
    [outcome_sentence, worst_year_sentence, withdrawal_growth_sentence, @note&.dig("context")].compact
  end

  private

  def headline_outcome
    case @rank
    when :worst then "the worst year to start the #{rate_label} rule"
    when :best then "the best year to start the #{rate_label} rule"
    else
      if depleted?
        "a #{rate_label} withdrawal ran out of money in year #{depletion_year_number}"
      elsif final_balance >= @initial_amount
        "#{compact_currency(@initial_amount)} grew to #{compact_currency(final_balance)} on a #{rate_label} withdrawal"
      else
        "#{compact_currency(@initial_amount)} fell to #{compact_currency(final_balance)} on a #{rate_label} withdrawal"
      end
    end
  end

  def outcome_sentence
    opening = "Retiring in #{year} with #{compact_currency(@initial_amount)} and a #{rate_label} inflation-adjusted withdrawal,"
    if depleted?
      "#{opening} the money ran out in year #{depletion_year_number} (#{year + @result[:depleted_at]})."
    elsif years_invested == Calculator::MILESTONES.max
      "#{opening} the portfolio #{growth_verb} #{compact_currency(final_balance)} after #{years_invested} years."
    else
      "#{opening} the portfolio was worth #{compact_currency(final_balance)} after #{pluralize_years(years_invested)}, as of the latest data."
    end
  end

  def worst_year_sentence
    return if invested_years.empty?

    worst_year = invested_years.min_by { |y| @market_data[y]["sp500_return"] }
    worst_return = @market_data[worst_year]["sp500_return"]
    if worst_return.negative?
      "Its worst year was #{worst_year}, when the S&P 500 lost #{format_percent(-worst_return)} including dividends."
    else
      "The S&P 500 never had a losing year over that span."
    end
  end

  def withdrawal_growth_sentence
    return unless depleted?

    starting = @initial_amount * @withdrawal_rate / 100.0
    ending = invested_years.reduce(starting) { |amount, y| amount * (1 + @market_data[y]["inflation"]) }
    "Inflation had pushed the yearly withdrawal from #{compact_currency(starting)} to #{compact_currency(ending)} by then."
  end

  # Calendar years whose market return the portfolio actually received.
  def invested_years
    @invested_years ||= begin
      span = depleted? ? @result[:depleted_at] : Calculator::MILESTONES.max
      (year...(year + span)).take_while { |y| @market_data.key?(y) }
    end
  end

  def years_invested
    invested_years.length
  end

  def depletion_year_number
    @result[:depleted_at] + 1
  end

  def final_balance
    @result[:final_portfolio]
  end

  def growth_verb
    final_balance >= @initial_amount ? "grew to" : "fell to"
  end

  def rate_label
    "#{format_number(@withdrawal_rate.to_f.round(2))}%"
  end

  def format_percent(fraction)
    "#{format_number((fraction * 100).round(1))}%"
  end

  def pluralize_years(count)
    count == 1 ? "1 year" : "#{count} years"
  end

  def compact_currency(value)
    if value >= 1_000_000
      "$#{format_number((value / 1_000_000.0).round(1))}M"
    elsif value >= 1_000
      "$#{format_number((value / 1_000.0).round(0))}K"
    else
      "$#{value.round(0)}"
    end
  end

  def format_number(number)
    number.to_s.delete_suffix(".0")
  end
end

module ApplicationHelper
  def format_currency(value)
    return "N/A" if value.nil?

    if value >= 1_000_000
      "$#{(value / 1_000_000.0).round(1)}M"
    elsif value >= 1_000
      "$#{(value / 1_000.0).round(0)}K"
    else
      "$#{value.round(0)}"
    end
  end
end

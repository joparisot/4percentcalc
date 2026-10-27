class MarketEvents
  PATH = Rails.root.join("lib/data/market_events.yml")

  def self.all
    @all ||= YAML.load_file(PATH).map { |event| { year: event["year"], label: event["label"] } }.freeze
  end
end

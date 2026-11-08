class Rack::Attack
  API_LIMIT = 60
  API_PERIOD = 1.minute

  Rack::Attack.enabled = !Rails.env.test?
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  throttle("api/ip", limit: API_LIMIT, period: API_PERIOD) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  self.throttled_responder = lambda do |request|
    match = request.env["rack.attack.match_data"]
    retry_after = match[:period] - (match[:epoch_time] % match[:period])

    [
      429,
      { "Content-Type" => "application/json", "Retry-After" => retry_after.to_s, "Cache-Control" => "no-store" },
      [{ error: "Rate limit exceeded. Max #{API_LIMIT} requests per minute per IP." }.to_json]
    ]
  end
end

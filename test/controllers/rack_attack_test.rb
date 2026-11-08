require "test_helper"

class RackAttackTest < ActionDispatch::IntegrationTest
  setup do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.enabled = true
  end

  teardown do
    Rack::Attack.enabled = false
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  test "61st API request within a minute is throttled" do
    60.times do
      get "/api/v1/data"
      assert_response :success
    end

    get "/api/v1/data"
    assert_response :too_many_requests
    assert_equal "application/json", response.media_type
    assert response.headers["Retry-After"].to_i.positive?
    assert_equal "Rate limit exceeded. Max 60 requests per minute per IP.", response.parsed_body["error"]
  end

  test "non-API paths are not throttled" do
    61.times { get "/methodology.md" }
    assert_response :success
  end
end

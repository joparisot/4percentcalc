ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/autorun"
require "capybara/rails"
require "capybara/minitest"

class ActiveSupport::TestCase
  # Add helper methods here
end

class ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1000]
end

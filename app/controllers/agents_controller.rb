class AgentsController < ApplicationController
  before_action :load_calculator
  before_action :set_cache_headers

  def llms
    years = @calculator.available_years
    @first_year = years.first
    @last_year = years.last
    render formats: :text, content_type: "text/plain"
  end

  def methodology
    @fee_example = @calculator.fee_example
    render formats: :text, content_type: "text/markdown"
  end

  private

  def load_calculator
    @calculator = Calculator.new
  end

  def set_cache_headers
    expires_in 1.day, public: true
  end
end

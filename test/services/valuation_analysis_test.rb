require "test_helper"

class ValuationAnalysisTest < ActiveSupport::TestCase
  def setup
    @analysis = ValuationAnalysis.new(Calculator.new)
  end

  test "buckets sum to the number of points" do
    assert_equal @analysis.points.size, @analysis.buckets.sum { |bucket| bucket[:count] }
  end

  test "today's CAPE is present" do
    today = @analysis.today
    assert_equal 2026, today[:year]
    assert_operator today[:cape], :>, 0
  end

  test "percentile is share of start years strictly below" do
    assert_equal 100, @analysis.percentile(@analysis.today[:cape])
    assert_operator @analysis.percentile(@analysis.highest_start[:cape]), :>=, 95
    assert_equal 0, @analysis.percentile(0)
  end

  test "points are sorted and carry earnings yield" do
    years = @analysis.points.map { |p| p[:year] }
    assert_equal years.sort, years
    point = @analysis.points.first
    assert_equal (100.0 / point[:cape]).round(1), point[:earnings_yield]
  end

  test "correlation is strongly negative" do
    assert_operator @analysis.correlation, :<, -0.7
  end
end

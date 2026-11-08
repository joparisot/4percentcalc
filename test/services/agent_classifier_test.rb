require "test_helper"

class AgentClassifierTest < ActiveSupport::TestCase
  def classify(user_agent, path = "/")
    AgentClassifier.classify(user_agent: user_agent, path: path)
  end

  test "training crawlers" do
    assert_equal "training_crawler", classify("Mozilla/5.0 (compatible; GPTBot/1.0)")
    assert_equal "training_crawler", classify("claudebot/1.0")
  end

  test "agent fetchers" do
    assert_equal "agent_fetch", classify("Mozilla/5.0 AppleWebKit/537.36; compatible; ChatGPT-User/1.0")
    assert_equal "agent_fetch", classify("Claude-User/1.0")
    assert_equal "agent_fetch", classify("claude-code/1.2")
  end

  test "browsers" do
    assert_equal "browser", classify("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/120.0 Safari/537.36")
  end

  test "api clients" do
    assert_equal "api_client", classify("curl/8.4.0", "/api/v1/backtest")
    assert_equal "api_client", classify("", "/api/v1/data")
    assert_equal "api_client", classify(nil, "/llms.txt")
    assert_equal "api_client", classify("python-requests/2.31", "/methodology.md")
  end

  test "other" do
    assert_equal "other", classify("", "/")
    assert_equal "other", classify("curl/8.4.0", "/")
  end
end

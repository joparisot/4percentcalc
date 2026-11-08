require "test_helper"

class AgentsControllerTest < ActionDispatch::IntegrationTest
  test "llms.txt is plain text with the key sections" do
    get "/llms.txt"
    assert_response :success
    assert_equal "text/plain", response.media_type
    assert_includes response.body, "# The 4% Rule Calculator"
    assert_includes response.body, "/api/v1/backtest"
    assert_includes response.body, "1926"
    assert_includes response.body, "github.com/joparisot/4percentcalc"
    assert_includes response.headers["Cache-Control"], "max-age=86400"
  end

  test "methodology.md is markdown with the fee example" do
    get "/methodology.md"
    assert_response :success
    assert_equal "text/markdown", response.media_type
    assert_includes response.body, "# Methodology"

    one_percent = Calculator.new.fee_example[1]
    assert_includes response.body, "#{one_percent}% with a 1% annual fee"
  end

  test "html methodology page links to the markdown version" do
    get methodology_path
    assert_response :success
    assert_select "a[href='/methodology.md']"
  end

  test "footer links to llms.txt" do
    get root_path
    assert_select "a[href='/llms.txt']", text: "For AI agents"
  end

  test "root page has the copy prompt button" do
    get root_path
    assert_select "button[data-action='click->calculator#copyPrompt']" do
      assert_select "[data-calculator-target='promptLabel']", text: "Customize this scenario with your AI"
    end
  end

  test "year detail page has the copy prompt button with scenario data" do
    get year_detail_path(1966)
    assert_select "button[data-controller='agent-prompt'][data-action='click->agent-prompt#copy']" \
                  "[data-agent-prompt-initial-amount-value='1000000'][data-agent-prompt-starting-year-value='1966']"
  end
end

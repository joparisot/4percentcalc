require "test_helper"

class CalculatorControllerTest < ActionDispatch::IntegrationTest
  test "index renders with default values" do
    get root_path
    assert_response :success
    assert_select "h1", "The 4% Rule Calculator"
    assert_select "input[name='initial_amount'][value='1000000']"
  end

  test "index accepts custom parameters" do
    get root_path, params: { initial_amount: 500_000, withdrawal_rate: 5.0 }
    assert_response :success
    assert_select "input[name='initial_amount'][value='500000']"
  end

  test "methodology page renders" do
    get methodology_path
    assert_response :success
    assert_select "h1", "Methodology"
    assert_select "h2", "How It Works"
    assert_select "h2", "Data Sources"
    assert_select "h2", "Assumptions"
  end

  test "calculate returns turbo stream" do
    post calculate_path, params: { initial_amount: 1_000_000, withdrawal_rate: 4.0 },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_match "turbo-stream", response.body
  end

  test "year_detail renders HTML page with chart" do
    get year_detail_path(year: 1990), params: { initial_amount: 1_000_000, withdrawal_rate: 4.0 }
    assert_response :success
    assert_select "h2", /Portfolio Value: Started in 1990/
    assert_select "[data-controller='chart']"
    assert_select "a[href*='#{root_path}']", text: /Back to Calculator/
  end

  test "every year page has a unique title, outcome phrase, and short description" do
    titles = Calculator.new.available_years.map do |year|
      get year_detail_path(year)
      assert_response :success

      title = css_select("title").text
      assert_includes title, year.to_s
      assert_match(/Ran out in year \d+|Ended with \$/, title)

      description = css_select("meta[name='description']").first["content"]
      assert description.present?, "#{year} meta description is empty"
      assert_operator description.length, :<, 160, "#{year} meta description too long: #{description}"
      title
    end
    assert_equal titles.uniq, titles
  end

  test "1966 page has a depletion headline, summary, related years, and prev/next links" do
    get year_detail_path(1966)
    assert_response :success
    assert_select "h1", "Retiring in 1966: a 4% withdrawal ran out of money in year 31"
    assert_select "main p", /the money ran out in year 31 \(1996\)/
    assert_select "a[rel='prev'][href='#{year_detail_path(1965)}']"
    assert_select "a[rel='next'][href='#{year_detail_path(1967)}']"
    assert_select "nav", /Other retirements that ran out of money/
    assert_select "nav a[href='#{year_detail_path(1930)}']"
  end

  test "worst start year from the homepage gets the worst-year headline" do
    get year_detail_path(1930)
    assert_select "h1", "Retiring in 1930: the worst year to start the 4% rule"
  end

  test "surviving year pages skip the related failed years" do
    get year_detail_path(1976)
    assert_select "h1", /Retiring in 1976: \$1M grew to \$[\d.]+M on a 4% withdrawal/
    assert_select "nav", text: /Other retirements that ran out of money/, count: 0
  end

  test "prev/next links stop at the ends of the data and keep scenario params" do
    get year_detail_path(1927), params: { withdrawal_rate: 5.0 }
    assert_select "a[rel='prev']", count: 0
    assert_select "a[rel='next'][href='#{year_detail_path(1928, withdrawal_rate: 5.0)}']"
    assert_select "title", /on the 5% Rule/

    get year_detail_path(Calculator.new.available_years.last)
    assert_select "a[rel='next']", count: 0
  end

  test "year page includes WebPage and BreadcrumbList JSON-LD" do
    get year_detail_path(2000)
    data = css_select("script[type='application/ld+json']").map { |node| JSON.parse(node.text) }

    page = data.find { |d| d["@type"] == "WebPage" }
    assert_equal css_select("h1").text, page["name"]
    assert_equal css_select("meta[name='description']").first["content"], page["description"]
    assert page["datePublished"].present?
    assert_equal "WebSite", page.dig("isPartOf", "@type")

    crumbs = data.find { |d| d["@type"] == "BreadcrumbList" }["itemListElement"]
    assert_equal ["Home", "Retirement Start Years", "2000"], crumbs.map { |c| c["name"] }
  end

  test "year page canonical ignores query params" do
    get year_detail_path(2000), params: { initial_amount: 500_000 }
    assert_select "link[rel='canonical'][href='http://www.example.com#{year_detail_path(2000)}']"
  end

  test "year page without data returns 404" do
    get year_detail_path(1800)
    assert_response :not_found
  end

  test "index links to notable years" do
    get root_path
    YearSummary.featured_years.each do |year|
      assert_select "nav a[href='#{year_detail_path(year)}']", /#{year}/
    end
  end

  test "sitemap lists every year page without query params and with lastmod" do
    sitemap = File.read(Rails.root.join("public/sitemap.xml"))
    Calculator.new.available_years.each do |year|
      assert_match %r{<url><loc>https://www\.4percentcalc\.com/year_detail/#{year}</loc><lastmod>\d{4}-\d{2}-\d{2}</lastmod>}, sitemap
    end
    refute_match %r{<loc>[^<]*\?}, sitemap
  end
end

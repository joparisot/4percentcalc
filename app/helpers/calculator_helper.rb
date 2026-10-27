module CalculatorHelper
  YEAR_PAGES_PUBLISHED_ON = "2026-01-25".freeze

  def year_detail_structured_data(summary)
    page_url = year_detail_url(summary.year)
    [
      {
        "@context" => "https://schema.org",
        "@type" => "WebPage",
        "name" => summary.headline,
        "description" => summary.description,
        "url" => page_url,
        "datePublished" => YEAR_PAGES_PUBLISHED_ON,
        "isPartOf" => { "@type" => "WebSite", "name" => "The 4% Rule Calculator", "url" => root_url }
      },
      {
        "@context" => "https://schema.org",
        "@type" => "BreadcrumbList",
        "itemListElement" => [
          { "@type" => "ListItem", "position" => 1, "name" => "Home", "item" => root_url },
          { "@type" => "ListItem", "position" => 2, "name" => "Retirement Start Years", "item" => root_url(anchor: "start-years") },
          { "@type" => "ListItem", "position" => 3, "name" => summary.year.to_s, "item" => page_url }
        ]
      }
    ]
  end

  def json_ld_tag(data)
    tag.script(json_escape(data.to_json).html_safe, type: "application/ld+json")
  end

  def format_rate(rate)
    number_with_precision(rate, precision: 2, strip_insignificant_zeros: true)
  end

  # Homepage FAQ entries; answers are HTML so the visible list can link out, and
  # are stripped to plain text for the FAQPage JSON-LD.
  def homepage_faq_items(faq)
    at4, at35, at3 = faq[:by_rate].values_at(4.0, 3.5, 3.0)
    survived = at4[:total_periods] - at4[:failed_years].size
    link_class = "text-[#7C3AED] font-medium hover:underline"
    multiple = ->(rate) { "#{number_with_precision(100 / rate, precision: 1, strip_insignificant_zeros: true)}x" }
    year_links = ->(years) { to_sentence(years.map { |y| link_to(y.to_s, year_detail_path(y), class: link_class) }) }

    failed_answer =
      if at4[:failed_years].empty?
        ["In this data, a 4% withdrawal never ran out of money within 30 years for any start year since #{faq[:first_year]}."]
      else
        [
          "With a 4% withdrawal, #{at4[:failed_years].size} of #{at4[:total_periods]} start years failed the 30-year test: ",
          year_links.call(at4[:failed_years]), ". ",
          "Each year's page shows how the portfolio and withdrawals evolved until the money ran out.",
          (" Retirements starting in " if at4[:later_failed_years].any?),
          (year_links.call(at4[:later_failed_years]) if at4[:later_failed_years].any?),
          (" also ran out eventually, but only after more than 30 years." if at4[:later_failed_years].any?)
        ].compact
      end

    [
      {
        question: "What is the 4% rule?",
        answer: [
          "The 4% rule says you can withdraw 4% of your portfolio in your first year of retirement, then raise that dollar amount by inflation every year, and the money should last at least 30 years. ",
          "It comes from William Bengen's 1994 research and the later ",
          link_to("Trinity study", "https://en.wikipedia.org/wiki/Trinity_study", target: "_blank", rel: "noopener noreferrer", class: link_class),
          ", which tested withdrawals against historical U.S. market returns. ",
          "This calculator replays the rule for every start year since #{faq[:first_year]}."
        ]
      },
      {
        question: "How much do I need to retire using the 4% rule?",
        answer: [
          "Multiply your annual spending by 25, which is the same as dividing it by 4%. ",
          "For example, spending #{number_to_currency(faq[:example_spending], precision: 0)} a year means you need #{number_to_currency(faq[:example_portfolio], precision: 0)}. ",
          "Choose \"I know my spending\" in the calculator above to ",
          link_to("run your own number", root_path(annual_spending: faq[:example_spending], withdrawal_rate: 4.0), class: link_class),
          " through every historical start year."
        ]
      },
      {
        question: "Is the 4% rule still safe today?",
        answer: [
          "Historically it mostly held up: a 4% withdrawal from an all-stock portfolio lasted 30 years in #{survived} of #{at4[:total_periods]} start years since #{faq[:first_year]} (#{format_rate(at4[:success_rate])}%). ",
          "Past returns don't guarantee future ones, though, and the rule was designed for 30-year retirements. ",
          "A lower withdrawal rate or a willingness to cut spending in bad years adds a margin of safety, especially for early retirees."
        ]
      },
      {
        question: "What about a 3% or 3.5% withdrawal rate?",
        answer: [
          "Lower rates have been safer: over 30 years, 3.5% succeeded in #{format_rate(at35[:success_rate])}% of start years and 3% in #{format_rate(at3[:success_rate])}%, versus #{format_rate(at4[:success_rate])}% at 4%. ",
          "The trade-off is a bigger portfolio, about #{multiple.call(3.5)} your annual spending at 3.5% and #{multiple.call(3.0)} at 3%, instead of 25x. ",
          "Try ",
          link_to("3.5%", root_path(withdrawal_rate: 3.5), class: link_class),
          " or ",
          link_to("3%", root_path(withdrawal_rate: 3.0), class: link_class),
          " in the calculator."
        ]
      },
      {
        question: "Which years did the 4% rule fail?",
        answer: failed_answer
      },
      {
        question: "Does the 4% rule account for inflation?",
        answer: [
          "Yes. Each year's withdrawal is the previous year's amount raised by that year's CPI inflation, so your spending power stays the same. ",
          "For example, a $40,000 first-year withdrawal becomes $41,200 after a year of 3% inflation. ",
          "Portfolio balances on this site are in nominal dollars, not adjusted to today's money."
        ]
      },
      {
        question: "Does this include bonds, fees, or Social Security?",
        answer: [
          "The main backtest assumes the whole portfolio is in the S&P 500 with dividends reinvested. ",
          "Next to it, the calculator shows the Trinity study's stock/bond mixes (75/25, 50/50, 25/75 and all bonds), using 10-year U.S. Treasuries rebalanced every year. ",
          "It ignores fees, taxes, and income such as Social Security or a pension. ",
          "Fees and taxes would make results worse, while Social Security lowers how much your portfolio has to cover, so you can subtract expected benefits from your spending before using the calculator. ",
          "See the ",
          link_to("methodology", methodology_path, class: link_class),
          " for every assumption."
        ]
      },
      {
        question: "Where does the data come from?",
        answer: [
          "S&P 500 total returns and CPI inflation come from ",
          link_to("Robert Shiller's dataset", "https://shillerdata.com/", target: "_blank", rel: "noopener noreferrer", class: link_class),
          " at Yale University. ",
          "The calculator uses January-to-January annual returns from #{faq[:first_year]} through #{faq[:last_year]}, and tests every start year with at least 10 years of data. ",
          "The ",
          link_to("methodology page", methodology_path, class: link_class),
          " explains exactly how each year is calculated."
        ]
      }
    ].map { |item| item.merge(answer: safe_join(item[:answer])) }
  end

  def faq_structured_data(items)
    {
      "@context" => "https://schema.org",
      "@type" => "FAQPage",
      "mainEntity" => items.map do |item|
        {
          "@type" => "Question",
          "name" => item[:question],
          "acceptedAnswer" => { "@type" => "Answer", "text" => CGI.unescapeHTML(strip_tags(item[:answer])) }
        }
      end
    }
  end

  FEE_OPTIONS = [0, 0.05, 0.1, 0.25, 0.5, 0.75, 1, 1.5, 2].freeze

  def format_fee(fee)
    format("%g", fee.to_f)
  end

  def fee_options(selected)
    fees = (FEE_OPTIONS + [selected]).map(&:to_f).uniq.sort
    options_for_select(fees.map { |fee| [fee.zero? ? "None" : "#{format_fee(fee)}%", format_fee(fee)] }, format_fee(selected))
  end

  def year_detail_scenario_params(initial_amount:, withdrawal_rate:, fee:, stock_allocation: nil)
    { initial_amount: initial_amount, withdrawal_rate: withdrawal_rate }
      .merge(fee.positive? ? { fee: format_fee(fee) } : {})
      .merge(stock_allocation ? { stock_allocation: stock_allocation } : {})
  end
end

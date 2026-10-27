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
end

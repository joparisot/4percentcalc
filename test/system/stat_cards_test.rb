require "test_helper"

class StatCardsTest < ActionDispatch::SystemTestCase
  VIEWPORT_WIDTHS = { desktop: 1440, tablet: 1024, mobile: 390 }.freeze

  def with_viewport(width)
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: width, height: 1000, deviceScaleFactor: 1, mobile: width < 640)
    yield
  ensure
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
  end

  def stat_card_layout
    page.evaluate_script(<<~JS)
      [...document.querySelectorAll("[data-stat-card]")].map((card) => {
        const label = card.querySelector("[data-stat-card-label]")
        const icon = card.querySelector("[data-stat-card-icon]")
        const range = document.createRange()
        range.selectNodeContents(label)
        const text = range.getBoundingClientRect()
        const iconBox = icon.getBoundingClientRect()
        const cardBox = card.getBoundingClientRect()
        const padding = parseFloat(getComputedStyle(card).paddingRight)
        return {
          label: label.innerText.replace(/\\s+/g, " "),
          overlapsIcon: text.right > iconBox.left && text.left < iconBox.right && text.bottom > iconBox.top && text.top < iconBox.bottom,
          labelClipped: label.scrollWidth > label.clientWidth || text.right > cardBox.right - padding,
          iconOutsideCard: iconBox.right > cardBox.right - padding + 0.5
        }
      })
    JS
  end

  VIEWPORT_WIDTHS.each do |name, width|
    test "stat card labels are fully visible and clear of their icons on #{name} (#{width}px)" do
      with_viewport(width) do
        visit root_path
        assert_selector "[data-stat-card]", count: 4

        stat_card_layout.each do |card|
          refute card["overlapsIcon"], "#{card['label']} label overlaps its icon at #{width}px"
          refute card["labelClipped"], "#{card['label']} label is clipped at #{width}px"
          refute card["iconOutsideCard"], "#{card['label']} icon overflows its card at #{width}px"
        end
      end
    end
  end
end

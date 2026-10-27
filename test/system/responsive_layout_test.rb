require "test_helper"

class ResponsiveLayoutTest < ActionDispatch::SystemTestCase
  VIEWPORT_WIDTHS = { desktop: 1440, tablet: 1024, mobile: 390 }.freeze

  def with_viewport(width)
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: width, height: 1000, deviceScaleFactor: 1, mobile: width < 640)
    yield
  ensure
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
  end

  def header_layout
    page.evaluate_script(<<~JS)
      (() => {
        const row = document.querySelector("header .h-16")
        const rowBox = row.getBoundingClientRect()
        const items = [...row.querySelectorAll("a, p, span, nav, [aria-hidden]")]
          .filter((el) => el.getClientRects().length && !el.querySelector("a, p, span, nav, [aria-hidden]"))
          .map((el) => ({ text: el.textContent.trim() || el.tagName, box: el.getBoundingClientRect() }))
        const overlaps = []
        items.forEach((a, i) => items.slice(i + 1).forEach((b) => {
          if (a.box.right > b.box.left + 0.5 && a.box.left < b.box.right - 0.5 && a.box.bottom > b.box.top + 0.5 && a.box.top < b.box.bottom - 0.5) overlaps.push(`${a.text} / ${b.text}`)
        }))
        return {
          overlaps: overlaps,
          overflowing: items.filter((i) => i.box.right > document.documentElement.clientWidth || i.box.top < rowBox.top || i.box.bottom > rowBox.bottom).map((i) => i.text),
          wrapped: items.filter((i) => i.box.height > 40).map((i) => i.text)
        }
      })()
    JS
  end

  VIEWPORT_WIDTHS.each do |name, width|
    test "page headers fit on one row without overlap on #{name} (#{width}px)" do
      with_viewport(width) do
        [ root_path, year_detail_path(1966), methodology_path ].each do |path|
          visit path
          assert_selector "header"
          layout = header_layout
          assert_empty layout["overlaps"], "header items overlap on #{path} at #{width}px"
          assert_empty layout["overflowing"], "header items overflow on #{path} at #{width}px"
          assert_empty layout["wrapped"], "header items wrap on #{path} at #{width}px"
        end
      end
    end

    test "heatmap legend stays inside its card on #{name} (#{width}px)" do
      with_viewport(width) do
        visit root_path
        legend = find("[data-heatmap-legend]")
        clipped = page.evaluate_script(<<~JS, legend)
          ((legend) => {
            const limit = legend.parentElement.getBoundingClientRect().right
            return [...legend.children].filter((item) => item.getBoundingClientRect().right > limit + 0.5).map((item) => item.innerText)
          })(arguments[0])
        JS
        assert_empty clipped, "heatmap legend items are clipped at #{width}px"
      end
    end

    test "homepage does not scroll sideways on #{name} (#{width}px)" do
      with_viewport(width) do
        visit root_path
        assert_selector "#stocks-vs-bonds"
        assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, width
      end
    end

    test "withdrawal rate tick labels line up with the slider on #{name} (#{width}px)" do
      with_viewport(width) do
        visit root_path
        offsets = page.evaluate_script(<<~JS)
          (() => {
            const slider = document.querySelector("input[type=range][name=withdrawal_rate]")
            const box = slider.getBoundingClientRect()
            const min = parseFloat(slider.min), max = parseFloat(slider.max)
            return [...document.querySelectorAll("[data-rate-tick]")].map((tick) => {
              const rate = parseFloat(tick.dataset.rateTick)
              const label = tick.getBoundingClientRect()
              const thumbCentre = box.left + 8 + (box.width - 16) * (rate - min) / (max - min)
              const inside = label.left >= box.left - 0.5 && label.right <= box.right + 0.5
              const centred = Math.abs((label.left + label.right) / 2 - thumbCentre) <= 2
              return { rate: rate, ok: inside && (rate === min || rate === max || centred) }
            })
          })()
        JS
        assert_equal 4, offsets.size
        offsets.each { |tick| assert tick["ok"], "#{tick['rate']}% tick is misaligned at #{width}px" }
      end
    end
  end

  test "horizon selector keeps its custom arrow clear of the selected text" do
    visit root_path
    select = find("#horizon-select")
    assert_equal "none", page.evaluate_script("getComputedStyle(arguments[0]).appearance", select)
    assert_operator page.evaluate_script("parseFloat(getComputedStyle(arguments[0]).paddingRight)", select), :>=, 28
  end
end

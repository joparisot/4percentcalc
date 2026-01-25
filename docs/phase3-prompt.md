# Phase 3 Prompt — Copy this into a new Claude Code session

Run with: `claude --dangerously-skip-permissions`

---

## Context

You're implementing Phase 3 (UI) for The 4% Rule Calculator — a historical backtesting tool for the 4% retirement rule.

**What's already done:**
- Rails 7 app with Hotwire + Tailwind (in `/Users/jonathanparisot/projects/4percentcalc`)
- `Calculator` service class at `app/services/calculator.rb` with methods:
  - `backtest(initial_amount:, withdrawal_rate:, starting_year:)` → returns milestones hash
  - `backtest_all(initial_amount:, withdrawal_rate:)` → returns array of all starting years
  - `summary_stats(results, horizon: 30)` → returns success_rate, worst_year, best_year, median_final_value
- Historical data at `lib/data/shiller_data.json` (1927-2023)
- Routes: root → `calculator#index`, `/methodology` → `calculator#methodology`
- Tests passing

**Key files to read first:**
1. `~/4percent-rule-design-spec.md` — full design spec with colors, layout, components
2. `~/4percent-rule-prd.md` — product requirements and technical decisions
3. `docs/stitch-reference.html` — Stitch-generated HTML for visual inspiration (DO NOT copy features not in spec)
4. `app/services/calculator.rb` — the calculation logic you'll call from controllers

---

## Your Task: Implement Phase 3 UI

### 1. Calculator Page (`app/views/calculator/index.html.erb`)
- Header: app name "The 4% Rule Calculator", tagline, link to methodology
- Two inputs: Starting Amount ($1M default), Withdrawal Rate (4% default, slider 1-12%)
- 4 stat cards: Success Rate (30yr), Worst Starting Year, Best Starting Year, Median Final Value
- Heatmap table: rows = starting years (1927 onward), columns = Year 10/20/30/40/50
  - Cell colors based on portfolio health (see design spec for exact colors)
  - Show dollar values in cells
  - N/A for years without enough data
- Clicking a row shows detail chart below

### 2. Detail Chart (appears when row clicked)
- Title: "Portfolio Value: Started in [YEAR]"
- Line chart showing portfolio value over time (0-50 years)
- Use Chart.js
- Dashed line at $0

### 3. Live Updates with Hotwire
- When user changes inputs, table and stats update without page reload
- Use Turbo Frames or Stimulus

### 4. Methodology Page (`app/views/calculator/methodology.html.erb`)
- How It Works section (4% rule explanation with example)
- Data Sources section (link to Shiller data)
- Assumptions section (100% S&P 500, no taxes, annual withdrawals, dividends reinvested)

### 5. Styling
- Use colors from design spec (purple accent #7C3AED, heatmap colors)
- Use Stitch reference for visual inspiration ONLY
- DO NOT add features not in spec (no login, no sidebar, no export buttons, no "load more")

### 6. Mobile Responsive
- Inputs stack vertically on mobile
- Table scrolls horizontally

---

## Verification

When done:
1. Run `rails server` and verify at localhost:3000
2. Test inputs update table live
3. Test clicking a row shows chart
4. Test methodology page loads
5. Run `rails test` to ensure nothing broke
6. Commit and push to GitHub

---

## Files to modify/create:

- `app/controllers/calculator_controller.rb` — add logic to call Calculator service
- `app/views/calculator/index.html.erb` — main calculator UI
- `app/views/calculator/methodology.html.erb` — methodology content
- `app/views/layouts/application.html.erb` — update layout if needed
- `app/javascript/controllers/calculator_controller.js` — Stimulus for live updates
- `app/javascript/controllers/chart_controller.js` — Stimulus for Chart.js
- `config/importmap.rb` — add Chart.js
- `app/assets/tailwind/application.css` — custom styles if needed

Go!

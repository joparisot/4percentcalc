# Valuations page: does the starting CAPE predict how much you can withdraw?

**Linear:** JON-66
**Assignee:** Devin
**Goal:** Show the relationship between the stock market valuation at retirement and the withdrawal rate that would have survived 30 years, and put today's valuation on that chart.

## Why
- Responds to the "the 4% rule assumes average valuations, today isn't average" argument that comes up every time the calculator is shared.
- Shiller's CAPE is the valuation number the FIRE community already uses (ERN, Kitces). It's in the Shiller spreadsheet we already ship, so no new data source.
- Input-independent story, so it deserves its own page and can rank for "CAPE safe withdrawal rate" style searches.

## Metric decisions (brainstormed, settled)
- Valuation metric: **CAPE** (Shiller P/E10, January value of the start year). Show the earnings yield (100 / CAPE) in tooltips only.
  - Rejected: excess CAPE yield (same correlation with outcomes, -0.77 vs 0.77, less known), dividend yield (0.58), 10-yr yield (0.17).
- Outcome metric: **maximum 30-year safe withdrawal rate** for the 100% S&P 500 scenario, i.e. the highest first-year rate (to 0.01%) that does not run out before 30 withdrawals. Independent of visitor inputs.

## Data
- Extend `rake shiller:parse` to also write `lib/data/valuations.json`:
  `{ "source": "Robert Shiller, Yale (ie_data.xls), CAPE column", "as_of": "2026-01", "cape": { "1926": 11.3, ..., "2026": 39.6 } }`
  January CAPE for every year from 1926 through the latest January in the file (so "today" is covered even though that year has no return row).
- `Calculator#max_withdrawal_rate(starting_year:, horizon: 30, scenario:, fee: 0)`: binary search between 0.5 and 20, ~25 iterations, returns a Float rounded to 2 decimals. nil if the start year lacks `horizon` years of data.

## Page: `/valuations`
Header/nav like the methodology page (Calculator | Valuations | Methodology). Add a "Valuations" link to the homepage header and methodology nav.

1. **Headline + intro** (2 short paragraphs): what CAPE is in one sentence ("how many years of inflation-adjusted profit you pay for a share"), why it matters for withdrawal rates.
2. **Today callout**: "CAPE in January 2026: 39.6. The highest any retirement in this dataset started at was 27.1 (1929)." Plus percentile vs. the start years.
3. **Scatter chart** (Chart.js, Stimulus controller): x = CAPE at start, y = max 30-yr SWR (%). One point per start year 1926..(last year - 29). Points green if max SWR >= 4.0, red if below. Dashed vertical line at today's CAPE, labelled. Dashed horizontal line at 4%. Tooltip: "1966: CAPE 24.1 (earnings yield 4.1%), max safe rate 3.79%". Click a point to open `/year_detail/:year`.
4. **Bucket table**: CAPE ranges under 15, 15-20, 20-25, over 25. Columns: start years (count), survived 4% (n of n), median max SWR, lowest max SWR (link to that year). Computed live from data.
5. **Caveat paragraph**: only one start year above 25; 1996 (24.8) supported 7.4%; it's a tendency, not a law. Link to methodology.
6. JSON-LD not required. `<title>` and meta description set. Add page to `public/sitemap.xml` and mention it in `llms.txt`.

## Year detail pages
- Add a small chip under the headline: "CAPE at start: 24.1 (higher than 90% of start years)". Links to `/valuations`. Hidden if no CAPE for that year.

## Tests
- `test/services/calculator_test.rb`: max_withdrawal_rate for 1966 is between 3.7 and 3.9; for 1982 is above 8; nil for a year without 30 years of data.
- `test/services/valuation_analysis_test.rb`: buckets sum to the number of points; today's CAPE is present; percentile for the max-CAPE year is 100.
- `test/controllers/valuations_controller_test.rb`: GET /valuations 200, contains "CAPE", contains the today callout.
- `test/system/valuations_test.rb`: page renders the chart canvas and the bucket table; year detail page shows the CAPE chip and it links to /valuations.

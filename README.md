# The 4% Rule Calculator

Free, open-source retirement withdrawal backtester. It tests a starting portfolio and withdrawal rate against every historical start year, using Robert Shiller's S&P 500, 10-year Treasury and CPI data plus Nasdaq Composite from 1972.

Live at https://www.4percentcalc.com

## How the calculation works

- Withdraw at the start of each year.
- The first withdrawal is portfolio × rate; each following year's withdrawal is the previous one × (1 + that year's inflation).
- After the withdrawal, apply the year's portfolio return, then subtract the annual fee from the year-end balance.
- Mixed portfolios (stocks/10-year Treasuries) rebalance to the target mix every year.
- A start year "fails" if the balance hits zero before the horizon. Success rate = share of start years with at least horizon years of data that did not fail.

Full details: [/methodology.md](https://www.4percentcalc.com/methodology.md).

## Data sources

- S&P 500 total return, 10-year Treasury return and CPI inflation: Robert Shiller, Yale University (http://www.econ.yale.edu/~shiller/data.htm). Files: `lib/data/shiller_data.json`.
- Nasdaq Composite total return (1972 onward): DQYDJ, built from FRED NASDAQCOM. File: `lib/data/nasdaq_returns.json`.

## JSON API

No auth. Limited to 60 requests per minute per IP. Identical calls are cached for 24 hours.

- `GET /api/v1/backtest`: summary plus a result for every start year.
- `GET /api/v1/backtest/:starting_year`: one start year, plus a year-by-year `series`.
- `GET /api/v1/data`: raw yearly data and the scenario list.

Backtest parameters (all optional, unknown params are ignored):

- `initial_amount`: dollars, 1 to 1,000,000,000 (default 1000000)
- `annual_spending`: dollars; if present, the starting portfolio is spending / rate
- `withdrawal_rate`: percent, 0.5 to 20 (default 4.0)
- `fee`: annual fee in percent, 0 to 3 (default 0)
- `scenario`: `sp500` (default), `sp75`, `sp50`, `sp25`, `bonds`, `nasdaq`
- `horizon`: 10, 20, 30, 40 or 50 years (default 30)

Invalid values return HTTP 400 with `{"error": "..."}`; unknown start years return 404.

```
curl "https://www.4percentcalc.com/api/v1/backtest?initial_amount=1000000&withdrawal_rate=4.0"
```

```json
{
  "inputs": { "initial_amount": 1000000, "annual_spending": 40000, "withdrawal_rate": 4.0, "fee": 0.0, "scenario": "sp500", "scenario_label": "100% S&P 500", "horizon": 30 },
  "summary": { "success_rate": 95.2, "total_periods": 70, "worst_year": 1966, "best_year": 1982, "median_final_value": 1234567 },
  "results": [
    { "starting_year": 1926, "depleted_at": null, "final_portfolio": 123, "milestones": { "10": 1, "20": 2, "30": 3, "40": 4, "50": 5 } }
  ],
  "meta": { "data_range": { "first_year": 1926, "last_year": 2025 }, "methodology_url": "...", "data_url": "...", "source_url": "...", "license": "...", "ui_url": "..." }
}
```

Values above are illustrative; `results` has one entry per start year.

## For AI agents

- [/llms.txt](https://www.4percentcalc.com/llms.txt): overview, API and rules in plain text.
- [/methodology.md](https://www.4percentcalc.com/methodology.md): the calculation in markdown.
- The calculator has a "Copy prompt for your AI assistant" button that copies a ready-made prompt with the current scenario, the API URLs and the rules, so an assistant can model a variation the site doesn't offer.

## Running locally

Needs Ruby 3.1.2.

```
bundle install
bin/dev
```

`bin/dev` runs `Procfile.dev`: the Rails server and the Tailwind CSS watcher. The app is at http://localhost:3000.

## Tests

```
bin/rails test
```

## License

MIT. Data: Robert Shiller (Yale) and DQYDJ.

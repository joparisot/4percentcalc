# Make year_detail pages rank on their own

**Assignee:** Devin
**Goal:** Turn the 102 `/year_detail/:year` pages from templated data tables into pages that can rank for "retire in 1966", "4% rule 2000 retirement", "what if I retired in 1929" style searches.

## Why
Search Console (Oct 24 to 27) shows these pages already appearing in positions 1 to 5 for long-tail queries, with zero clicks. They have a generic title ("Retired in 1966: Year-by-Year") and no prose, so Google has little to match and users have no reason to click. The homepage can't rank for year-specific searches; these pages can.

## Requirements

### 1. Unique headline and summary per year
- Replace the templated `<h1>` with a year-specific headline that states the outcome. Examples:
  - 1966: "Retiring in 1966: the worst year to start the 4% rule"
  - 2000: "Retiring in 2000: surviving the dot-com crash and 2008 on 4%"
  - 1976: "Retiring in 1976: $1M became $21.5M on a 4% withdrawal"
- Add a 2 to 4 sentence summary under the headline, generated from the data, that explains what happened: final balance (or depletion year), worst drawdown year, and what market event drove it.
- Store per-year context (1 sentence about the historical event) in a YAML or Ruby hash in `lib/data/` so it can be edited without touching views. Only need entries for notable years (roughly 25); fall back to a data-only summary for others.

### 2. Title and meta description
- `<title>`: "Retiring in {year} on the 4% Rule: {outcome phrase} | 4% Rule Calculator" where outcome phrase is e.g. "Ran out in year 25" or "Ended with $14.3M".
- Meta description: the first sentence of the summary.
- Keep canonical as-is (already strips query params).

### 3. Internal linking
- Add "Previous year / Next year" links at the bottom of each year page.
- Add a "Notable years" block on the homepage linking to 6 to 8 key years (1929, 1930, 1966, 1973, 1976, 2000, 2008) so Google discovers them from the strongest page.
- Add related years ("Other retirements that failed: 1930, 1966, 1967, 1969, 1970") on failed-year pages.

### 4. Structured data
- Add JSON-LD `WebPage` with `name`, `description`, `datePublished`, `isPartOf` (the site).
- Add `BreadcrumbList`: Home > Retirement Start Years > {year}.

### 5. Sitemap
- Verify all 102 year URLs are in `sitemap.xml` without query params, with `lastmod`.
- After deploy, resubmit sitemap in Search Console.

## Out of scope
- Changing the calculation logic.
- Changing the year page layout beyond the header and footer link blocks.

## Tests
- Controller test: each year page returns 200, `<title>` contains the year and an outcome phrase, meta description is non-empty and under 160 chars.
- Unit test for the summary generator: given a result hash for a depleted year and a surviving year, produces the expected phrases.
- System test: homepage "Notable years" links resolve to the right year pages.

## Acceptance
- Visiting `/year_detail/1966` shows a unique headline, a summary mentioning depletion, and prev/next links.
- `view-source` shows unique title, description, JSON-LD.
- Search Console shows year pages indexed (check 2 weeks after deploy; baseline Oct 27: 0 of 102 indexed).

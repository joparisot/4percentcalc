# Reverse calculator ("how much do I need?") and FAQ section on homepage

**Assignee:** Devin
**Goal:** Capture "how much do I need to retire" searches, which have far more volume than "4% rule calculator", and give Google more text to match on the homepage.

## Why
- Search Console shows a visitor arriving via the query "80000/4": they wanted the reverse math (spending to portfolio), not the forward one.
- The homepage currently has one paragraph of text. Pages with a short FAQ typically rank for more query variations and can get FAQ rich results.
- Current ranking for core queries is ~position 9. More relevant on-page content is one of the few levers we control directly.

## Requirements

### 1. Reverse calculator
- Add a second, smaller input mode above or beside the existing "Starting Portfolio" input: a toggle "I know my portfolio" / "I know my spending".
- In spending mode: user enters annual spending. We compute required portfolio = spending / withdrawal rate (at 4% that's 25x) and show it prominently: "You need $2,000,000 to withdraw $80,000/yr at 4%."
- Changing spending or the withdrawal rate updates the required portfolio live, and runs the existing backtest with that portfolio so all charts update (reuse the current Turbo flow).
- The share link should encode the mode and the spending value (`?annual_spending=80000&withdrawal_rate=4.0`).
- Keep the default mode as the current portfolio mode so nothing changes for existing links.

### 2. FAQ section
- Add an FAQ section below the results, before the footer, with 6 to 8 questions. Plain text answers, 2 to 4 sentences each, numbers pulled from the live calculation where relevant (so they stay correct if data updates). Proposed questions:
  1. What is the 4% rule?
  2. How much do I need to retire using the 4% rule? (25x annual spending; worked example)
  3. Is the 4% rule still safe today?
  4. What about 3% or 3.5%? (link to the calculator with that rate preset)
  5. Which years did the 4% rule fail? (list from data, link to year pages)
  6. Does the 4% rule account for inflation?
  7. Does this include bonds, fees, or Social Security? (no; explain)
  8. Where does the data come from? (Shiller; link to methodology)
- Mark up with JSON-LD `FAQPage` schema.
- Use `<details>`/`<summary>` or a simple always-open list. Keep it accessible and no JS required.

### 3. Copy and title tweaks
- Update the homepage `<h1>` subtitle to include both intents, e.g. "See how much you need, and whether it would have lasted in every market since 1927."
- Keep the `<title>` as-is unless length allows adding "How Much Do You Need?".

## Out of scope
- Monte Carlo, bonds, flexible spending rules.
- Any backend changes to the backtest.

## Tests
- Unit test: required portfolio calculation for several spending/rate pairs, including rounding.
- Controller test: homepage renders FAQ with 6+ questions and valid `FAQPage` JSON-LD.
- System test: switch to spending mode, enter 80000 at 4%, see "$2,000,000", charts update; share link round-trips to the same state.

## Acceptance
- Entering $80,000 spending at 4% shows $2,000,000 required and runs the backtest on $2M.
- FAQ visible on homepage; Rich Results Test (https://search.google.com/test/rich-results) passes for FAQPage.
- Search Console: within 4 weeks, impressions for queries containing "how much" or "need to retire" appear (baseline Oct 27: none).

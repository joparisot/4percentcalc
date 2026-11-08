# Community launch: Reddit, Hacker News, calculator lists

**Assignee:** Jonathan (manual, not Devin)
**Goal:** 5+ backlinks and 500+ real visitors in 2 weeks, to lift Google ranking from ~position 9 into the top 5 for "4% rule calculator".

**Core message (use this angle everywhere):** "I backtested the 4% rule against every retirement start year since 1927. Here's what actually happened." Lead with the data story, not the tool. The tool is the proof.

**Why this angle:** FIRE communities downvote product pitches but upvote data. The horizon chart (every start year, one bar each) and the "retire in 1966 vs 1982" contrast are the hook. FIRECalc and cFIREsim already exist, so "another calculator" is not news. "Here's the full history in one picture, click any year" is.

**Ground rules**
- Disclose you built it, every time. Reddit and HN both punish hidden promotion.
- Put the link in the post body on r/Fire and HN. On r/financialindependence, only use the Wednesday self-promo thread.
- Reply to every comment within the first 2 hours. Early replies decide whether a post takes off.
- Don't ask friends to upvote (HN bans for this).
- Before posting, use a Reddit account with some comment history. If yours is fresh, spend 2 to 3 days leaving 5 to 10 helpful comments in r/Fire and r/financialindependence first.

---

## Prep (do once, ~30 min)

- [ ] Screenshot the horizon chart at $1M / 4% / 30 years (full width, light background). Save as `horizon-1m-4pct.png`. This is the image for Reddit.
- [ ] Screenshot the year detail page for 1966 (worst 30-year outcome) and 2000 (dot-com start). Optional, for comments.
- [ ] Confirm these shareable URLs load and look right:
  - https://www.4percentcalc.com/
  - https://www.4percentcalc.com/year_detail/1966
  - https://www.4percentcalc.com/year_detail/2000
  - https://www.4percentcalc.com/year_detail/1982
  - https://www.4percentcalc.com/methodology
- [ ] Check Search Console the morning before each post so you can report "before" traffic.

---

## Day 1 (Tue, Wed or Thu): r/Fire

**URL:** https://www.reddit.com/r/Fire/submit
**Format:** Image post (upload `horizon-1m-4pct.png`) with text body. Flair: "General Question" or "Advice Request" if no "Tool" flair exists.

**Title:**
```
I backtested the 4% rule against every retirement start year since 1927. 93% success. 4 of the 5 failures started between 1966 and 1970.
```

**Body:**
```
I kept seeing "the 4% rule has a 95% success rate" and wanted to see the actual year-by-year picture instead of one number.

So I pulled Shiller's S&P 500 and inflation data (1927 to today) and ran a $1M portfolio at a 4% inflation-adjusted withdrawal for every possible 30-year retirement start year. Each bar in the chart is one start year and what you'd have left after 30 years.

A few things that surprised me:

- Success rate is 93%, not 95%. Only 5 start years fail within 30 years: 1930, 1966, 1967, 1969 and 1970. Retire in 1966 and you're out of money before year 30. Retire ten years later in 1976 and you end with $21.5M.
- The late 60s were worse for retirees than the Great Depression. 1929 actually survives (ends with $2.8M). 1930 doesn't. The 1966 to 1970 cohort got 15 years of flat stocks plus 70s inflation, and inflation-adjusted withdrawals ate the portfolio.
- Retiring in 2000 (dot-com peak) is still alive at year 20 but down to $642K on a $1M start. 2001 is at $457K.
- The median outcome is ending with $9.3M, about 9x your starting portfolio. The 4% rule is extremely conservative in most histories and disastrous in a few.

Disclosure: I built the calculator to produce this (4percentcalc.com, free, no signup). You can change the starting amount and withdrawal rate, and click any year to see the year-by-year balance. Happy to run other scenarios in the comments if people are curious (3.5%? 5%? 40-year horizon?).

Caveats: 100% US stocks, no bonds, no fees, no Social Security, fixed inflation-adjusted withdrawals. It's a stress test of the rule itself, not a retirement plan.
```

**After posting:**
- [ ] Reply to the first 5 to 10 comments. Offer to run their scenario and link the specific year_detail page.
- [ ] If someone asks "how is this different from FIRECalc", answer honestly: it's simpler, one chart for all start years, drill into any year. FIRECalc is more configurable.

---

## Day 2: Hacker News (Show HN)

**URL:** https://news.ycombinator.com/submit
**Timing:** Tue, Wed or Thu, 8:00 to 9:30 am Eastern. Not Monday, not Friday.
**Guidelines:** https://news.ycombinator.com/showhn.html

**Title:**
```
Show HN: What happened to everyone who retired on the 4% rule since 1927
```

**URL field:** `https://www.4percentcalc.com/`

**Text field:** leave empty (HN prefers URL plus a first comment).

**First comment (post immediately after submitting):**
```
I built this because every 4% rule discussion quotes a single success rate and I wanted to see the full distribution of outcomes by start year.

It runs a fixed inflation-adjusted withdrawal against Shiller's S&P 500 total return and CPI data (1927 to 2026) for every possible start year, and shows what's left after 10/20/30/40/50 years. Click any year for the year-by-year path.

Some findings: 93% of 30-year retirements succeed. Only five start years fail: 1930, 1966, 1967, 1969, 1970. 1929 survives, 1930 doesn't. The 1966 cohort is broke before year 30, while 1976 ends with 21x the starting portfolio. Median outcome is ending with about 9x what you started with.

Stack: Rails 8, Hotwire/Turbo for the live recalculation, Chart.js, Heroku. The Shiller data is parsed from his Excel file with a rake task. No accounts, no tracking beyond GA.

Known limitations: 100% US equities, no fees, no bonds, no flexible spending rules. Those are the next things I'd add if people find it useful. Would love feedback on what's missing or wrong.
```

**After posting:**
- [ ] Stay online for 3 hours. HN comments will be technical (data source, survivorship, why no bonds). Answer directly, concede fair points.
- [ ] If it reaches the front page, expect 5K to 20K visitors. Check Heroku dyno count.

---

## Day 3 (Wednesday only): r/financialindependence self-promo thread

**Where:** Find the pinned "Weekly Self-Promotion Thread - Wednesday, [date]" at https://www.reddit.com/r/financialindependence/ (sort by Hot, it's pinned). Comment inside it. Never post this as a standalone thread; it gets removed.

**Comment:**
```
I built a free 4% rule backtester: https://www.4percentcalc.com

It runs your portfolio and withdrawal rate against every retirement start year since 1927 (Shiller data) and shows one bar per start year, so you see the whole distribution instead of a single success percentage. Click any year for the year-by-year balance.

Findings so far: 93% success at 4%/30 years. Only five start years fail: 1930, 1966, 1967, 1969, 1970. The 1966 start runs dry before year 30; 1976 ends with $21.5M on $1M.

Limitations: 100% US stocks, no bonds, no fees. Would appreciate feedback on what to add next.
```

---

## Day 3 to 5: One more subreddit (pick one, not all)

Pick **r/leanfire** (most sensitive to the "is 4% safe" question) or **r/ChubbyFIRE**. Don't repost the same text; reframe for the audience.

**r/leanfire URL:** https://www.reddit.com/r/leanfire/submit

**Title:**
```
If you're lean, the 4% rule's bad years matter more. Here's every start year since 1927 at 3.5% vs 4%.
```

**Body:**
```
Ran a backtest of inflation-adjusted withdrawals against every start year since 1927 using Shiller data. At 4%/30 years, 93% of start years succeed; the five failures are 1930, 1966, 1967, 1969 and 1970. Drop to 3.5% and [fill in: check the site and put the real success rate here] succeed, and the worst case is [fill in].

For a lean budget the difference between 3.5% and 4% is real money, so I thought the side-by-side was worth sharing. Chart attached is the 4% case.

Disclosure: I built the tool (4percentcalc.com, free). Caveats: 100% US stocks, no bonds, no Social Security, fixed withdrawals.
```
- [ ] Before posting, actually run 3.5% on the site and fill in the two bracketed numbers.

---

## Week 1 to 2: Calculator lists and backlinks

These are the pages Google already associates with "best FIRE calculator". A link from any of them is worth more than 100 Reddit upvotes for ranking.

### 1. GitHub: awesome-fire-calculators (easiest, do first)
- [ ] Go to https://github.com/thewellfrog/awesome-fire-calculators
- [ ] Fork, edit README, add under "Simple Calculators":
  ```
  - [4% Rule Calculator](https://www.4percentcalc.com) - Backtests a fixed 4% withdrawal against every retirement start year since 1927 using Shiller data. One bar per start year, click any year for the year-by-year path.
  ```
- [ ] Open a PR titled "Add 4% Rule Calculator (historical backtest)".

### 2. Bogleheads wiki
- [ ] Register at https://www.bogleheads.org/forum/ (needed to edit the wiki or post).
- [ ] Post in the forum first (the wiki editors look for a forum thread). Forum: https://www.bogleheads.org/forum/viewforum.php?f=10 (Investing - Theory, News & General). Title: `4% Rule Calculator: historical backtest of every start year since 1927`. Body: adapt the r/financialindependence comment above, add that it's free and has no accounts.
- [ ] Then request a wiki listing: leave a note on https://bogleheads.org/wiki/Talk:Retirement_calculators_and_spending with the URL, calculator type "HStr" (historical stress test), runtime "Web", spending model "fixed inflation-adjusted".

### 3. Blog listicles (email the author)
For each, find the contact page, send the email below, personalize the first line with the article name.

- [ ] Can I Retire Yet? "The Best Retirement Calculators": https://www.caniretireyet.com/the-best-retirement-calculators/ (contact via https://www.caniretireyet.com/contact/)
- [ ] The Ways To Wealth "6 Best Free FI Calculators": https://www.thewaystowealth.com/financial-independence-calculators/ (contact page in footer)
- [ ] Wallet Hacks "Best Early Retirement Calculators": https://wallethacks.com/best-early-retirement-calculators/ (contact page in footer)
- [ ] Get Rich Slowly "Picking the best online retirement calculator": https://www.getrichslowly.org/retirement-calculator/ (contact page in footer)

**Email template:**
```
Subject: A free 4% rule backtester for your "[article name]" roundup

Hi [name],

I read your [article name] piece while researching retirement calculators and it's the most thorough comparison I found.

I built a free tool that might fit: https://www.4percentcalc.com

It backtests a fixed inflation-adjusted withdrawal against every retirement start year since 1927 (Shiller S&P 500 and CPI data) and shows one bar per start year, so readers see the full distribution rather than one success rate. Clicking any year shows the year-by-year balance. No signup, no ads.

It's intentionally simpler than FIRECalc and cFIREsim: one question (would the 4% rule have worked, starting any given year?), answered visually.

If it's useful for the article, I'd be grateful for a mention. Happy to answer any questions about the methodology (https://www.4percentcalc.com/methodology).

Thanks,
Jonathan
```

---

## Measure

Check 7 and 14 days after the first post:
- [ ] GA: sessions by source (reddit.com, news.ycombinator.com, github.com, each blog domain)
- [ ] Search Console: average position for "4% rule calculator" and "4 percent rule calculator" (baseline Oct 27: ~9.5)
- [ ] Search Console: total impressions per day (baseline Oct 26: 103)
- [ ] Backlinks landed (target 5): GitHub README, Bogleheads wiki, any blog

Success = position under 6 on the two main queries, or 2+ blog links, within 14 days.

const formatCurrency = (value) => `$${value.toLocaleString('en-US')}`

// params: { initial_amount | annual_spending, withdrawal_rate, horizon, fee }; startingYear is optional.
export function buildAgentPrompt(params, origin, startingYear = null) {
  const rate = parseFloat(params.withdrawal_rate)
  const fee = parseFloat(params.fee) || 0
  const horizon = parseInt(params.horizon) || 30
  const spendingMode = params.annual_spending !== undefined
  const spending = spendingMode ? parseInt(params.annual_spending) : null
  const amount = spendingMode ? Math.round(spending * 100 / rate) : parseInt(params.initial_amount)
  const yearOne = spendingMode ? spending : Math.round(amount * rate / 100)

  const scenarioParts = spendingMode
    ? [`${formatCurrency(spending)}/year of spending, which at ${rate.toFixed(1)}% needs a ${formatCurrency(amount)} starting portfolio`]
    : [
        `${formatCurrency(amount)} starting portfolio`,
        `${rate.toFixed(1)}% initial withdrawal rate (that's ${formatCurrency(yearOne)} in year one, then adjusted for inflation)`
      ]
  if (fee > 0) scenarioParts.push(`${fee}% annual fee`)
  scenarioParts.push(`${horizon}-year horizon`, '100% S&P 500')
  if (startingYear) scenarioParts.push(`starting in ${startingYear}`)

  const query = new URLSearchParams()
  query.set(spendingMode ? 'annual_spending' : 'initial_amount', spendingMode ? spending : amount)
  query.set('withdrawal_rate', rate.toFixed(1))
  query.set('fee', fee)
  query.set('scenario', 'sp500')
  query.set('horizon', horizon)
  query.set('src', 'agent')
  const backtestPath = startingYear ? `/api/v1/backtest/${startingYear}` : '/api/v1/backtest'

  return `I'm using 4percentcalc.com to test retirement withdrawal scenarios. Current scenario: ${scenarioParts.join(', ')}.

I want to explore a variation the site doesn't offer: [describe it, e.g. "add $20,000/year of Social Security starting in year 10" or "a 3.5% rate but only for start years after 1950"].

Please use the site's data and methodology rather than making up numbers:
- Backtest API for this scenario: ${origin}${backtestPath}?${query.toString()}
- Raw yearly data (S&P 500, 10-year Treasuries, inflation, Nasdaq): ${origin}/api/v1/data?src=agent
- Methodology: ${origin}/methodology.md?src=agent
- Source code (MIT): https://github.com/joparisot/4percentcalc
- Overview for agents: ${origin}/llms.txt?src=agent

Rules the site uses: withdraw at the start of each year; the first withdrawal is portfolio × rate, and each later year's withdrawal is the previous one × (1 + that year's inflation); after the withdrawal apply the year's return, then the fee on the year-end balance; a start year fails if the balance hits zero before the horizon. Show me the success rate, worst and best start years, and the median ending balance, and tell me which of the rules you changed.`
}

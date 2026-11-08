import { Controller } from "@hotwired/stimulus"
import { marketEventsPlugin } from "controllers/market_events"
import { styleChip } from "controllers/scenario_chip"

export default class extends Controller {
  static SCENARIOS_KEY = "valuationTimelineScenarios"
  static DEFAULT_SCENARIOS = ["sp500"]

  static targets = ["canvas", "title", "dropdown", "horizonLabel", "chip"]
  static values = {
    data: Array,
    initialAmount: Number,
    dataThrough: Number,
    scenarios: Array,
    horizon: { type: Number, default: 30 },
    events: { type: Array, default: [] }
  }

  async connect() {
    const { Chart, registerables } = await import("https://cdn.jsdelivr.net/npm/chart.js@4.4.1/+esm")

    Chart.register(...registerables)
    this.Chart = Chart

    this.renderChart()
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
    }
  }

  get scenarioKeys() {
    return this.scenariosValue.map(scenario => String(scenario.key))
  }

  get selected() {
    let stored = null
    try { stored = JSON.parse(localStorage.getItem(this.constructor.SCENARIOS_KEY)) } catch (e) {}
    const keys = this.scenarioKeys
    const chosen = Array.isArray(stored) ? stored.map(String) : this.constructor.DEFAULT_SCENARIOS
    const valid = keys.filter(key => chosen.includes(key))
    return valid.length > 0 ? valid : keys.filter(key => this.constructor.DEFAULT_SCENARIOS.includes(key))
  }

  toggleScenario(event) {
    const key = event.currentTarget.dataset.scenario
    const selected = new Set(this.selected)
    if (selected.has(key)) {
      if (selected.size === 1) return
      selected.delete(key)
    } else {
      selected.add(key)
    }
    const next = this.scenarioKeys.filter(k => selected.has(k))
    try { localStorage.setItem(this.constructor.SCENARIOS_KEY, JSON.stringify(next)) } catch (e) {}
    this.renderChart()
  }

  updateChipControls(selected) {
    const last = selected.length === 1 ? selected[0] : null
    this.chipTargets.forEach((chip) => {
      const on = selected.includes(chip.dataset.scenario)
      chip.setAttribute("aria-pressed", String(on))
      styleChip(chip, chip.dataset.color, on)
      if (chip.dataset.scenario === last) {
        chip.setAttribute("aria-disabled", "true")
        chip.title = "At least one portfolio must be shown"
      } else {
        chip.removeAttribute("aria-disabled")
        chip.removeAttribute("title")
      }
    })
    this.canvasTarget.dataset.renderedScenarios = selected.join(",")
  }

  changeHorizon(event) {
    this.horizonValue = parseInt(event.target.value, 10)
    this.horizonLabelTargets.forEach(label => { label.textContent = this.horizonValue })
    this.renderChart()
  }

  renderChart() {
    if (!this.Chart || !this.hasCanvasTarget) return
    if (this.chart) this.chart.destroy()

    const rows = this.dataValue
    const horizon = this.horizonValue
    const selected = this.selected
    this.updateChipControls(selected)
    const scenarios = this.scenariosValue.filter(scenario => selected.includes(String(scenario.key)))
    const valueFor = (row, key = "sp500") => row.values[key]?.[horizon] ?? null
    const labels = rows.map(r => r.year)
    const initialAmount = this.initialAmountValue
    const dataThrough = this.dataThroughValue
    const events = this.eventsValue.filter(e => labels.includes(e.year))
    const hasValue = new Set(rows.filter(r => valueFor(r) !== null).map(r => r.year))
    const naStart = labels.findIndex(year => year <= dataThrough && !hasValue.has(year))
    const naEnd = labels.lastIndexOf(dataThrough)
    const eventByYear = new Map(events.map(e => [e.year, e.label]))
    this.canvasTarget.dataset.markedEvents = events.map(e => e.year).join(",")

    this.chart = new this.Chart(this.canvasTarget.getContext("2d"), {
      type: "line",
      plugins: [
        this.belowStartPlugin(initialAmount),
        this.naZonePlugin(naStart, naEnd),
        marketEventsPlugin(events.map(e => ({ index: labels.indexOf(e.year), label: e.label })))
      ],
      data: {
        labels,
        datasets: [
          ...scenarios.map(scenario => ({
            label: scenario.label,
            yAxisID: "y",
            data: rows.map(r => valueFor(r, scenario.key)),
            borderColor: scenario.color,
            backgroundColor: scenario.color,
            borderWidth: scenario.key === "sp500" ? 2.5 : 2,
            tension: 0.4,
            cubicInterpolationMode: "monotone",
            pointRadius: 0,
            pointHoverRadius: 4,
            spanGaps: false
          })),
          {
            label: "CAPE at start",
            yAxisID: "y1",
            data: rows.map(r => r.cape),
            borderColor: "#6B7280",
            backgroundColor: "#6B7280",
            borderWidth: 2,
            tension: 0.3,
            pointRadius: 0,
            pointHoverRadius: 4,
            spanGaps: false
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: { intersect: false, mode: "index" },
        onClick: (_event, _elements, chart) => {
          const active = chart.getActiveElements()
          if (active.length === 0) return
          const row = rows[active[0].index]
          if (row.year <= dataThrough) this.visit(`/year_detail/${row.year}`)
        },
        plugins: {
          legend: { display: false },
          tooltip: {
            backgroundColor: "#1F2937",
            titleColor: "#fff",
            bodyColor: "#fff",
            padding: 12,
            cornerRadius: 8,
            displayColors: false,
            callbacks: {
              title: (context) => context[0].label,
              label: (context) => {
                const value = context.raw
                if (context.dataset.yAxisID === "y1") {
                  return value === null ? "CAPE at start: n/a" : `CAPE at start: ${value.toFixed(1)}`
                }
                const scenario = scenarios[context.datasetIndex]
                if (value === null) {
                  const before = scenario.first_year && rows[context.dataIndex].year < scenario.first_year
                  return before ? `${scenario.label}: n/a before ${scenario.first_year}` : `${scenario.label}: Not enough history yet`
                }
                return `${scenario.label}: ${this.formatAxisCurrency(value)}`
              },
              footer: (context) => {
                const event = eventByYear.get(Number(context[0].label))
                return event ? `Year one: ${event}` : ""
              }
            }
          }
        },
        scales: {
          x: {
            grid: { display: false },
            ticks: { color: "#6B7280", font: { size: 12 }, maxTicksLimit: 10 },
            title: { display: true, text: "Starting year", color: "#6B7280", font: { size: 12 } }
          },
          y: {
            type: "linear",
            position: "left",
            min: 0,
            grace: "5%",
            grid: { color: "rgba(229, 231, 235, 0.5)" },
            ticks: { color: "#6B7280", font: { size: 12 }, callback: (value) => this.formatAxisCurrency(value) }
          },
          y1: {
            type: "linear",
            position: "right",
            min: 0,
            grid: { drawOnChartArea: false },
            ticks: { color: "#6B7280", font: { size: 12 } },
            title: { display: true, text: "CAPE", color: "#6B7280", font: { size: 12 } }
          }
        }
      }
    })
    this.canvasTarget.dataset.rendered = "true"
  }

  visit(url) {
    if (window.Turbo) {
      window.Turbo.visit(url)
    } else {
      window.location.href = url
    }
  }

  belowStartPlugin(initialAmount) {
    return {
      id: "belowStart",
      beforeDatasetsDraw: (chart) => {
        const { ctx, chartArea, scales: { y } } = chart
        const top = Math.min(Math.max(y.getPixelForValue(initialAmount), chartArea.top), chartArea.bottom)
        ctx.save()
        ctx.fillStyle = "rgba(239, 68, 68, 0.07)"
        ctx.fillRect(chartArea.left, top, chartArea.right - chartArea.left, chartArea.bottom - top)
        ctx.strokeStyle = "#9CA3AF"
        ctx.lineWidth = 2
        ctx.setLineDash([6, 6])
        ctx.beginPath()
        ctx.moveTo(chartArea.left, top)
        ctx.lineTo(chartArea.right, top)
        ctx.stroke()
        ctx.restore()
      }
    }
  }

  naZonePlugin(naStart, naEnd) {
    return {
      id: "naZone",
      beforeDatasetsDraw: (chart) => {
        if (naStart < 0 || naEnd < naStart) return
        const { ctx, chartArea, scales: { x } } = chart
        const left = naStart === 0 ? chartArea.left : (x.getPixelForValue(naStart - 1) + x.getPixelForValue(naStart)) / 2
        const right = (x.getPixelForValue(naEnd) + x.getPixelForValue(naEnd + 1)) / 2
        const width = right - left
        const centre = left + width / 2
        const middle = (chartArea.top + chartArea.bottom) / 2

        ctx.save()
        ctx.fillStyle = "rgba(156, 163, 175, 0.15)"
        ctx.fillRect(left, chartArea.top, width, chartArea.bottom - chartArea.top)
        ctx.fillStyle = "#9CA3AF"
        ctx.textAlign = "center"
        ctx.textBaseline = "middle"
        ctx.font = "600 14px Inter, system-ui, sans-serif"
        ctx.fillText("N/A", centre, middle)
        if (width > 120) {
          ctx.font = "12px Inter, system-ui, sans-serif"
          ctx.fillText("Not enough history yet", centre, middle + 18)
        }
        ctx.restore()
      }
    }
  }

  formatAxisCurrency(value) {
    if (value >= 1000000) return `$${parseFloat((value / 1000000).toFixed(1))}M`
    if (value >= 1000) return `$${Math.round(value / 1000)}K`
    return `$${value}`
  }
}

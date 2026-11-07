import { Controller } from "@hotwired/stimulus"
import { marketEventsPlugin } from "controllers/market_events"

export default class extends Controller {
  static targets = ["canvas", "dropdown", "title", "scaleButton", "scaleNote", "chip"]
  static values = {
    series: Object,
    scenarios: Array,
    events: { type: Array, default: [] },
    initialAmount: Number,
    horizon: { type: Number, default: 30 }
  }

  static SCALE_KEY = "horizonChartScale"
  static SCALES = ["linear", "logarithmic"]
  static SCENARIOS_KEY = "horizonChartScenarios"
  static DEFAULT_SCENARIOS = ["100", "50"]

  async connect() {
    // Dynamically import Chart.js
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

  changeHorizon(event) {
    this.horizonValue = parseInt(event.target.value, 10)
    this.updateTitle()
    this.renderChart()

    // Sync with hidden form field so it persists through Turbo updates
    const hiddenField = document.getElementById('horizon_hidden')
    if (hiddenField) {
      hiddenField.value = this.horizonValue
    }
  }

  setScale(event) {
    const scale = event.currentTarget.dataset.scale
    if (!this.constructor.SCALES.includes(scale)) return

    try { localStorage.setItem(this.constructor.SCALE_KEY, scale) } catch (e) {}
    this.renderChart()
  }

  get scenarioKeys() {
    return this.scenariosValue.map(scenario => String(scenario.key))
  }

  get selected() {
    let stored = null
    try { stored = JSON.parse(localStorage.getItem(this.constructor.SCENARIOS_KEY)) } catch (e) {}
    const keys = this.scenarioKeys
    const chosen = Array.isArray(stored) ? stored.map(String) : this.constructor.DEFAULT_SCENARIOS
    return keys.filter(key => key === "100" || chosen.includes(key))
  }

  toggleScenario(event) {
    const key = event.currentTarget.dataset.scenario
    if (key === "100") return
    const selected = new Set(this.selected)
    if (selected.has(key)) selected.delete(key)
    else selected.add(key)
    const next = this.scenarioKeys.filter(k => selected.has(k))
    try { localStorage.setItem(this.constructor.SCENARIOS_KEY, JSON.stringify(next)) } catch (e) {}
    this.renderChart()
  }

  updateChipControls(selected) {
    this.chipTargets.forEach((chip) => {
      const on = selected.includes(chip.dataset.scenario)
      const scenario = this.scenariosValue.find(s => String(s.key) === chip.dataset.scenario)
      chip.setAttribute("aria-pressed", String(on))
      chip.classList.toggle("bg-white", on)
      chip.classList.toggle("shadow-sm", on)
      chip.style.borderColor = on ? scenario.color : ""
      chip.style.color = on ? scenario.color : ""
    })
    this.canvasTarget.dataset.renderedScenarios = selected.join(",")
  }

  // An explicit choice wins; otherwise long horizons, where outliers dwarf typical outcomes, default to log.
  get scale() {
    let stored = null
    try { stored = localStorage.getItem(this.constructor.SCALE_KEY) } catch (e) {}
    if (this.constructor.SCALES.includes(stored)) return stored
    return this.horizonValue >= 40 ? "logarithmic" : "linear"
  }

  updateScaleControls(scale) {
    this.scaleButtonTargets.forEach((button) => {
      button.setAttribute("aria-pressed", String(button.dataset.scale === scale))
    })
    if (this.hasScaleNoteTarget) {
      this.scaleNoteTarget.classList.toggle("hidden", scale !== "logarithmic")
    }
    this.canvasTarget.dataset.renderedScale = scale
  }

  updateTitle() {
    if (this.hasTitleTarget) {
      this.titleTarget.textContent = `Portfolio Value After ${this.horizonValue} Years per Starting Year`
    }
  }

  renderChart() {
    if (!this.Chart || !this.hasCanvasTarget) return

    // Destroy existing chart
    if (this.chart) {
      this.chart.destroy()
    }

    const ctx = this.canvasTarget.getContext('2d')
    const selected = this.selected
    this.updateChipControls(selected)
    const seriesFor = (key) => this.seriesValue[key]?.[this.horizonValue] || []
    const horizonData = seriesFor("100")

    if (horizonData.length === 0) return

    // Every horizon shares the x-axis of the shortest one; later start years don't have enough history yet.
    const allYears = (this.seriesValue["100"]?.[10] || horizonData).map(d => d.year)
    const valueByYear = new Map(horizonData.map(d => [d.year, d.value]))
    const labels = [...new Set([...allYears, ...valueByYear.keys()])].sort((a, b) => a - b)
    const scenarios = this.scenariosValue.filter(scenario => selected.includes(String(scenario.key)))
    const rawByScenario = scenarios.map((scenario) => {
      const byYear = new Map(seriesFor(String(scenario.key)).map(d => [d.year, d.value]))
      return labels.map(year => byYear.has(year) ? byYear.get(year) : null)
    })
    const values = rawByScenario[0]
    const naIndex = values.findIndex((v, i) => v === null && values.slice(i).every(rest => rest === null))
    this.canvasTarget.dataset.naFrom = naIndex === -1 ? "" : labels[naIndex]
    const events = this.eventsValue.filter(e => labels.includes(e.year))
    const eventByYear = new Map(events.map(e => [e.year, e.label]))
    this.canvasTarget.dataset.markedEvents = events.map(e => e.year).join(",")
    const initialAmount = this.initialAmountValue
    const horizon = this.horizonValue
    const scale = this.scale
    const log = scale === "logarithmic"
    // Log axes can't show $0, so depleted years sit on the axis floor (the tooltip still says they ran out).
    const smallest = Math.min(...rawByScenario.flatMap(raw => raw.filter(v => v > 0)), initialAmount)
    const floor = 10 ** Math.floor(Math.log10(smallest))
    const plot = (series) => log ? series.map(v => v === null ? null : Math.max(v, floor)) : series

    const depletedIndexes = new Set()
    rawByScenario.forEach(raw => raw.forEach((v, i) => { if (v !== null && v <= 0) depletedIndexes.add(i) }))
    const depleted = [...depletedIndexes].sort((a, b) => a - b)
    this.canvasTarget.dataset.depletedYears = depleted.map(i => labels[i]).join(",")
    this.updateScaleControls(scale)

    const referenceLineData = values.map(v => v === null ? null : initialAmount)
    const lineDataset = (scenario, raw, index) => ({
      label: scenario.label,
      data: plot(raw),
      borderColor: scenario.color,
      backgroundColor: scenario.color,
      borderWidth: index === 0 ? 3 : 2,
      fill: false,
      tension: 0.3,
      cubicInterpolationMode: 'monotone',
      pointRadius: 0,
      pointHoverRadius: index === 0 ? 6 : 5,
      pointHoverBackgroundColor: scenario.color
    })
    const sp500 = { ...lineDataset(scenarios[0], values, 0), backgroundColor: 'rgba(107, 114, 128, 0.08)', fill: 'start' }
    const referenceLine = {
      label: `Initial Amount (${this.formatCurrency(initialAmount)})`,
      data: referenceLineData,
      borderColor: '#9CA3AF',
      borderWidth: 2,
      borderDash: [6, 6],
      pointRadius: 0,
      pointHoverRadius: 0,
      fill: false
    }
    const datasets = [
      sp500,
      referenceLine,
      ...scenarios.slice(1).map((scenario, i) => lineDataset(scenario, rawByScenario[i + 1], i + 1))
    ]
    const seriesValues = [values, null, ...rawByScenario.slice(1)]

    this.chart = new this.Chart(ctx, {
      type: 'line',
      plugins: [
        this.belowStartPlugin(initialAmount),
        this.naZonePlugin(naIndex),
        this.depletedMarkersPlugin(depleted),
        marketEventsPlugin(events.map(e => ({ index: labels.indexOf(e.year), label: e.label })))
      ],
      data: {
        labels: labels,
        datasets
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
          intersect: false,
          mode: 'index'
        },
        plugins: {
          // The HTML legend below the chart explains the line colours and the dashed line.
          legend: {
            display: false
          },
          tooltip: {
            backgroundColor: '#1F2937',
            titleColor: '#fff',
            bodyColor: '#fff',
            padding: 12,
            cornerRadius: 8,
            displayColors: false,
            filter: function(tooltipItem) {
              // Only show tooltip for the portfolios, not the reference line
              return tooltipItem.datasetIndex !== 1
            },
            callbacks: {
              title: function(context) {
                return `Started in ${context[0].label}, after ${horizon} years`
              },
              footer: (context) => {
                const event = eventByYear.get(Number(context[0].label))
                return event ? `Year one: ${event}` : ''
              },
              label: (context) => {
                const value = seriesValues[context.datasetIndex][context.dataIndex]
                const name = context.dataset.label
                if (value <= 0) return `${name}: ran out within ${horizon} years`
                let formatted
                if (value >= 1000000) {
                  formatted = `$${(value / 1000000).toFixed(1)}M`
                } else if (value >= 1000) {
                  formatted = `$${Math.round(value / 1000)}K`
                } else {
                  formatted = `$${value}`
                }
                return `${name}: ${formatted}`
              }
            }
          }
        },
        scales: {
          x: {
            grid: {
              display: false
            },
            ticks: {
              color: '#6B7280',
              font: {
                size: 12
              },
              maxTicksLimit: 10
            },
            title: {
              display: true,
              text: 'Starting Year',
              color: '#6B7280',
              font: {
                size: 12
              }
            }
          },
          y: {
            type: scale,
            ...(log ? { min: floor } : { min: 0, grace: '5%' }),
            grid: {
              color: 'rgba(229, 231, 235, 0.5)'
            },
            ticks: {
              color: '#6B7280',
              font: {
                size: 12
              },
              callback: (value) => (log && !this.isRoundLogTick(value)) ? '' : this.formatAxisCurrency(value)
            }
          }
        }
      }
    })
  }

  belowStartPlugin(initialAmount) {
    return {
      id: 'belowStart',
      beforeDatasetsDraw: (chart) => {
        const { ctx, chartArea, scales: { y } } = chart
        const top = Math.min(Math.max(y.getPixelForValue(initialAmount), chartArea.top), chartArea.bottom)
        ctx.save()
        ctx.fillStyle = 'rgba(239, 68, 68, 0.07)'
        ctx.fillRect(chartArea.left, top, chartArea.right - chartArea.left, chartArea.bottom - top)
        ctx.restore()
      }
    }
  }

  depletedMarkersPlugin(indexes) {
    return {
      id: 'depletedMarkers',
      afterDatasetsDraw: (chart) => {
        const { ctx, chartArea, scales: { x } } = chart
        ctx.save()
        ctx.fillStyle = '#EF4444'
        indexes.forEach((index) => {
          ctx.beginPath()
          ctx.arc(x.getPixelForValue(index), chartArea.bottom - 1, 3.5, 0, Math.PI * 2)
          ctx.fill()
        })
        ctx.restore()
      }
    }
  }

  naZonePlugin(naIndex) {
    return {
      id: 'naZone',
      beforeDatasetsDraw: (chart) => {
        if (naIndex <= 0) return
        const { ctx, chartArea, scales: { x } } = chart
        const left = (x.getPixelForValue(naIndex - 1) + x.getPixelForValue(naIndex)) / 2
        const width = chartArea.right - left
        const centre = left + width / 2

        ctx.save()
        ctx.fillStyle = 'rgba(156, 163, 175, 0.15)'
        ctx.fillRect(left, chartArea.top, width, chartArea.bottom - chartArea.top)
        ctx.fillStyle = '#9CA3AF'
        ctx.textAlign = 'center'
        ctx.textBaseline = 'middle'
        ctx.font = '600 14px Inter, system-ui, sans-serif'
        const middle = (chartArea.top + chartArea.bottom) / 2
        ctx.fillText('N/A', centre, middle)
        if (width > 120) {
          ctx.font = '12px Inter, system-ui, sans-serif'
          ctx.fillText('Not enough history yet', centre, middle + 18)
        }
        ctx.restore()
      }
    }
  }

  isRoundLogTick(value) {
    const mantissa = value / 10 ** Math.floor(Math.log10(value))
    return Math.abs(mantissa - 1) < 1e-6
  }

  formatAxisCurrency(value) {
    if (value >= 1000000) return `$${parseFloat((value / 1000000).toFixed(1))}M`
    return this.formatCurrency(value)
  }

  formatCurrency(value) {
    if (value >= 1000000) {
      return `$${(value / 1000000).toFixed(1)}M`
    } else if (value >= 1000) {
      return `$${Math.round(value / 1000)}K`
    }
    return `$${value}`
  }
}

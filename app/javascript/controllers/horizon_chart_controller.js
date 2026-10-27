import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas", "dropdown", "title", "scaleButton", "scaleNote"]
  static values = {
    data: Object,
    initialAmount: Number,
    horizon: { type: Number, default: 30 }
  }

  // Line colour by final value relative to the starting amount (JON-8).
  static BANDS = [
    { below: 1, color: '#EF4444' },
    { below: 4, color: '#F59E0B' },
    { below: Infinity, color: '#10B981' }
  ]

  static SCALE_KEY = "horizonChartScale"
  static SCALES = ["linear", "logarithmic"]

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
    const horizonData = this.dataValue[this.horizonValue] || []

    if (horizonData.length === 0) return

    // Every horizon shares the x-axis of the shortest one; later start years don't have enough history yet.
    const allYears = (this.dataValue[10] || horizonData).map(d => d.year)
    const valueByYear = new Map(horizonData.map(d => [d.year, d.value]))
    const labels = [...new Set([...allYears, ...valueByYear.keys()])].sort((a, b) => a - b)
    const values = labels.map(year => valueByYear.has(year) ? valueByYear.get(year) : null)
    const naIndex = values.findIndex((v, i) => v === null && values.slice(i).every(rest => rest === null))
    this.canvasTarget.dataset.naFrom = naIndex === -1 ? "" : labels[naIndex]
    const initialAmount = this.initialAmountValue
    const horizon = this.horizonValue
    const scale = this.scale
    const log = scale === "logarithmic"
    // Log axes can't show $0, so depleted years sit on the axis floor (the tooltip still says they ran out).
    const smallest = Math.min(...values.filter(v => v > 0), initialAmount)
    const floor = 10 ** Math.floor(Math.log10(smallest))
    const plotted = log ? values.map(v => v === null ? null : Math.max(v, floor)) : values
    this.updateScaleControls(scale)

    // Create reference line data (same value for all points)
    const referenceLineData = values.map(v => v === null ? null : initialAmount)

    this.chart = new this.Chart(ctx, {
      type: 'line',
      plugins: [this.naZonePlugin(naIndex)],
      data: {
        labels: labels,
        datasets: [
          {
            label: `Portfolio value after ${horizon} years`,
            data: plotted,
            borderColor: '#7C3AED',
            segment: {
              // A segment touching a weak year takes that year's colour, so drops into depletion read as red.
              borderColor: (ctx) => this.bandColor(Math.min(values[ctx.p0DataIndex], values[ctx.p1DataIndex]), initialAmount)
            },
            backgroundColor: 'rgba(107, 114, 128, 0.08)',
            borderWidth: 3,
            fill: 'start',
            tension: 0.3,
            cubicInterpolationMode: 'monotone',
            pointRadius: 0,
            pointHoverRadius: 6,
            pointHoverBackgroundColor: (ctx) => this.bandColor(values[ctx.dataIndex], initialAmount)
          },
          {
            label: `Initial Amount (${this.formatCurrency(initialAmount)})`,
            data: referenceLineData,
            borderColor: '#9CA3AF',
            borderWidth: 2,
            borderDash: [6, 6],
            pointRadius: 0,
            pointHoverRadius: 0,
            fill: false
          }
        ]
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
              // Only show tooltip for portfolio value, not reference line
              return tooltipItem.datasetIndex === 0
            },
            callbacks: {
              title: function(context) {
                return `Started in ${context[0].label}`
              },
              label: (context) => {
                const value = values[context.dataIndex]
                if (value <= 0) return `Ran out of money within ${horizon} years`
                let formatted
                if (value >= 1000000) {
                  formatted = `$${(value / 1000000).toFixed(1)}M`
                } else if (value >= 1000) {
                  formatted = `$${Math.round(value / 1000)}K`
                } else {
                  formatted = `$${value}`
                }
                return `${formatted} after ${horizon} years`
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

  bandColor(value, initialAmount) {
    const ratio = value / initialAmount
    return this.constructor.BANDS.find(band => ratio < band.below).color
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

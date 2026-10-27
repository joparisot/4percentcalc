import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas", "dropdown", "title"]
  static values = {
    data: Object,
    initialAmount: Number,
    horizon: { type: Number, default: 30 }
  }

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

    // Sort chronologically (oldest to newest)
    const sortedData = [...horizonData].sort((a, b) => a.year - b.year)

    const labels = sortedData.map(d => d.year)
    const values = sortedData.map(d => d.value)
    const initialAmount = this.initialAmountValue
    const horizon = this.horizonValue

    // Create reference line data (same value for all points)
    const referenceLineData = labels.map(() => initialAmount)

    this.chart = new this.Chart(ctx, {
      type: 'line',
      data: {
        labels: labels,
        datasets: [
          {
            label: `Portfolio value after ${horizon} years`,
            data: values,
            borderColor: '#7C3AED',
            backgroundColor: 'rgba(124, 58, 237, 0.1)',
            borderWidth: 3,
            fill: true,
            tension: 0.3,
            cubicInterpolationMode: 'monotone',
            pointRadius: 0,
            pointHoverRadius: 6,
            pointHoverBackgroundColor: '#7C3AED'
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
          legend: {
            display: true,
            position: 'bottom',
            labels: {
              usePointStyle: true,
              padding: 20
            }
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
              label: function(context) {
                const value = context.raw
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
            min: 0,
            grace: '5%',
            grid: {
              color: 'rgba(229, 231, 235, 0.5)'
            },
            ticks: {
              color: '#6B7280',
              font: {
                size: 12
              },
              callback: (value) => this.formatAxisCurrency(value)
            }
          }
        }
      }
    })
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

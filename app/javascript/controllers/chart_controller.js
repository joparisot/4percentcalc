import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas"]
  static values = { data: Array }

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

  renderChart() {
    const ctx = this.canvasTarget.getContext('2d')
    const data = this.dataValue

    const labels = data.map(d => `Year ${d.year}`)
    const values = data.map(d => d.value)

    this.chart = new this.Chart(ctx, {
      type: 'line',
      data: {
        labels: labels,
        datasets: [{
          label: 'Portfolio Value',
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
        }]
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
            display: false
          },
          tooltip: {
            backgroundColor: '#1F2937',
            titleColor: '#fff',
            bodyColor: '#fff',
            padding: 12,
            cornerRadius: 8,
            displayColors: false,
            callbacks: {
              label: function(context) {
                const value = context.raw
                if (value >= 1000000) {
                  return `$${(value / 1000000).toFixed(1)}M`
                } else if (value >= 1000) {
                  return `$${Math.round(value / 1000)}K`
                }
                return `$${value}`
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
              maxTicksLimit: 6
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
              callback: function(value) {
                if (value >= 1000000) {
                  return `$${parseFloat((value / 1000000).toFixed(1))}M`
                } else if (value >= 1000) {
                  return `$${Math.round(value / 1000)}K`
                }
                return `$${value}`
              }
            }
          }
        }
      }
    })
  }
}

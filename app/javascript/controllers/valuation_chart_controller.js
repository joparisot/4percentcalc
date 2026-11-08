import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    points: Array,
    today: Object,
    inProgress: { type: Array, default: [] },
    threshold: { type: Number, default: 4 }
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

  renderChart() {
    if (!this.Chart || !this.hasCanvasTarget) return
    if (this.chart) this.chart.destroy()

    const threshold = this.thresholdValue
    const today = this.todayValue
    const data = this.pointsValue.map(p => ({ x: p.cape, y: p.max_swr, year: p.year, earningsYield: p.earnings_yield }))
    const running = this.inProgressValue.map(p => ({ x: p.cape, y: p.max_swr_so_far, year: p.year, earningsYield: p.earnings_yield, yearsElapsed: p.years_elapsed, alive: p.four_percent_alive }))
    const datasets = [data, running]
    const colorFor = (point) => point.y >= threshold ? "#16A34A" : "#DC2626"

    this.chart = new this.Chart(this.canvasTarget.getContext("2d"), {
      type: "scatter",
      plugins: [this.referenceLinesPlugin(threshold, today)],
      data: {
        datasets: [{
          data,
          pointBackgroundColor: data.map(colorFor),
          pointBorderColor: data.map(colorFor),
          pointRadius: 5,
          pointHoverRadius: 7
        }, {
          data: running,
          pointStyle: "circle",
          pointBackgroundColor: "#FFFFFF",
          pointBorderColor: "#6B7280",
          pointBorderWidth: 2,
          pointRadius: 5,
          pointHoverRadius: 7
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        layout: { padding: { top: 8, right: 16 } },
        onClick: (_event, elements) => {
          if (elements.length === 0) return
          this.visit(`/year_detail/${datasets[elements[0].datasetIndex][elements[0].index].year}`)
        },
        onHover: (event, elements) => {
          event.native.target.style.cursor = elements.length > 0 ? "pointer" : "default"
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
              title: () => "",
              label: (context) => {
                const p = context.raw
                if (context.datasetIndex === 1) {
                  return `${p.year}: CAPE ${p.x.toFixed(1)} (earnings yield ${p.earningsYield.toFixed(1)}%), ${p.yearsElapsed} years in, highest rate that has lasted so far ${p.y.toFixed(2)}%`
                }
                return `${p.year}: CAPE ${p.x.toFixed(1)} (earnings yield ${p.earningsYield.toFixed(1)}%), max safe rate ${p.y.toFixed(2)}%`
              }
            }
          }
        },
        scales: {
          x: {
            type: "linear",
            min: 0,
            max: Math.ceil(Math.max(today.cape, ...data.map(p => p.x), ...running.map(p => p.x))) + 2,
            grid: { display: false },
            ticks: { color: "#6B7280", font: { size: 12 } },
            title: { display: true, text: "CAPE at the start of retirement (Shiller P/E10)", color: "#6B7280", font: { size: 12 } }
          },
          y: {
            min: 0,
            grid: { color: "rgba(229, 231, 235, 0.5)" },
            ticks: { color: "#6B7280", font: { size: 12 }, callback: (value) => `${value}%` },
            title: { display: true, text: "Highest withdrawal rate that lasted 30 years", color: "#6B7280", font: { size: 12 } }
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

  referenceLinesPlugin(threshold, today) {
    const todayLabel = `Today: CAPE ${Number(today.cape).toFixed(1)}`
    return {
      id: "valuationReferenceLines",
      afterDatasetsDraw: (chart) => {
        const { ctx, chartArea, scales: { x, y } } = chart
        const yPixel = y.getPixelForValue(threshold)
        const xPixel = x.getPixelForValue(today.cape)

        ctx.save()
        ctx.setLineDash([6, 6])
        ctx.lineWidth = 1.5
        ctx.strokeStyle = "#6B7280"
        ctx.fillStyle = "#6B7280"
        ctx.font = "600 12px Inter, system-ui, sans-serif"

        ctx.beginPath()
        ctx.moveTo(chartArea.left, yPixel)
        ctx.lineTo(chartArea.right, yPixel)
        ctx.stroke()

        ctx.beginPath()
        ctx.moveTo(xPixel, chartArea.top)
        ctx.lineTo(xPixel, chartArea.bottom)
        ctx.stroke()

        ctx.setLineDash([])
        ctx.textAlign = "left"
        ctx.textBaseline = "bottom"
        ctx.fillText(`${threshold}% rule`, chartArea.left + 6, yPixel - 4)
        ctx.textAlign = "right"
        ctx.textBaseline = "top"
        ctx.fillText(todayLabel, xPixel - 6, chartArea.top + 4)
        ctx.restore()
      }
    }
  }
}

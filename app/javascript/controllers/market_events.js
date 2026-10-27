// Chart.js plugin marking major market events: dashed lines under the data, labels on top when there is room.
// Each marker is { index, label }, where index is a (possibly fractional) position on the category x-axis.
export function marketEventsPlugin(markers) {
  const positions = (chart) => markers
    .map((marker, row) => ({ ...marker, row, px: chart.scales.x.getPixelForValue(marker.index) }))
    .filter(({ px }) => px >= chart.chartArea.left && px <= chart.chartArea.right)

  return {
    id: 'marketEvents',
    beforeDatasetsDraw(chart) {
      const { ctx, chartArea } = chart
      ctx.save()
      ctx.strokeStyle = 'rgba(107, 114, 128, 0.45)'
      ctx.lineWidth = 1
      ctx.setLineDash([4, 4])
      positions(chart).forEach(({ px }) => {
        ctx.beginPath()
        ctx.moveTo(px, chartArea.top)
        ctx.lineTo(px, chartArea.bottom)
        ctx.stroke()
      })
      ctx.restore()
    },
    afterDatasetsDraw(chart) {
      const { ctx, chartArea } = chart
      if (chartArea.right - chartArea.left < 560) return

      ctx.save()
      ctx.font = '500 11px Inter, system-ui, sans-serif'
      ctx.textBaseline = 'top'
      positions(chart).forEach(({ px, label, row }) => {
        const width = ctx.measureText(label).width
        const x = px + 4 + width > chartArea.right ? px - 4 - width : px + 4
        const y = chartArea.top + 2 + (row % 2) * 16
        ctx.fillStyle = 'rgba(255, 255, 255, 0.85)'
        ctx.fillRect(x - 2, y - 1, width + 4, 14)
        ctx.fillStyle = '#4B5563'
        ctx.fillText(label, x, y)
      })
      ctx.restore()
    }
  }
}

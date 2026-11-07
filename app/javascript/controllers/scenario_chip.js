const OFF_DOT = "#D1D5DB"

function rgba(hex, alpha) {
  const n = parseInt(hex.replace("#", ""), 16)
  return `rgba(${(n >> 16) & 255}, ${(n >> 8) & 255}, ${n & 255}, ${alpha})`
}

export function styleChip(button, color, on) {
  const dot = button.querySelector("span")
  button.style.backgroundColor = on ? rgba(color, 0.12) : "#FAFAFA"
  button.style.borderColor = on ? color : "#D1D5DB"
  button.style.color = on ? color : "#6B7280"
  button.classList.toggle("font-semibold", on)
  button.classList.toggle("font-medium", !on)
  if (dot) dot.style.backgroundColor = on ? color : OFF_DOT
}

export function copyToClipboard(text, labelElement, successText) {
  const onSuccess = () => {
    if (!labelElement) return
    const original = labelElement.textContent
    labelElement.textContent = successText
    setTimeout(() => { labelElement.textContent = original }, 2000)
  }

  if (navigator.clipboard && window.isSecureContext) {
    navigator.clipboard.writeText(text).then(onSuccess)
  } else {
    const textarea = document.createElement('textarea')
    textarea.value = text
    textarea.style.position = 'fixed'
    textarea.style.opacity = '0'
    document.body.appendChild(textarea)
    textarea.select()
    document.execCommand('copy')
    document.body.removeChild(textarea)
    onSuccess()
  }
}

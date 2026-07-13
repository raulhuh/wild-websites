import { chromium } from 'playwright'
import path from 'path'

const [,, htmlPath, outPng] = process.argv
if (!htmlPath || !outPng) {
  console.error('Usage: node scripts/screenshot.mjs <html-file> <output-png>')
  process.exit(2)
}

const errors = []
const browser = await chromium.launch()
const page = await browser.newPage({ viewport: { width: 1440, height: 900 } })
page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()) })
page.on('pageerror', err => errors.push(String(err)))

await page.goto('file://' + path.resolve(htmlPath))
await page.waitForTimeout(1500) // Zeit für Animationen/Async-Assets
await page.screenshot({ path: outPng, fullPage: true })
await browser.close()

if (errors.length) {
  console.error('Console errors found:\n' + errors.join('\n'))
  process.exit(1)
}
console.log('OK: screenshot saved to ' + outPng)

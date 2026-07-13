import { chromium } from 'playwright'
import path from 'path'

const [,, htmlPath, outPng, widthArg] = process.argv
const width = widthArg ? parseInt(widthArg) : 1440
const height = width < 800 ? 800 : 900

const errors = []
const browser = await chromium.launch()
const page = await browser.newPage({ viewport: { width, height } })
page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()) })
page.on('pageerror', err => errors.push(String(err)))

await page.goto('file://' + path.resolve(htmlPath))
await page.waitForTimeout(1500)

// Durch die Seite scrollen, damit IntersectionObserver-Reveals triggern
const totalH = await page.evaluate(() => document.body.scrollHeight)
for (let y = 0; y < totalH; y += Math.floor(height * 0.7)) {
  await page.evaluate(v => window.scrollTo(0, v), y)
  await page.waitForTimeout(220)
}
await page.evaluate(() => window.scrollTo(0, 0))
await page.waitForTimeout(1200)

await page.screenshot({ path: outPng, fullPage: true })
await browser.close()

if (errors.length) {
  console.error('Console errors found:\n' + errors.join('\n'))
  process.exit(1)
}
console.log('OK: screenshot saved to ' + outPng)

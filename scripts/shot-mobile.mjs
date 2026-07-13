import { chromium } from 'playwright'
import path from 'path'

const [,, htmlPath, outPrefix] = process.argv
const errors = []
const browser = await chromium.launch()
const page = await browser.newPage({ viewport: { width: 390, height: 844 } })
page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()) })
page.on('pageerror', err => errors.push(String(err)))

await page.goto('file://' + path.resolve(htmlPath))
await page.waitForTimeout(1800)

for (const d of [0, 830, 10935]) {
  const y = d === 0 ? 0 : d * 2 + 844
  await page.evaluate(v => window.scrollTo(0, v), y)
  await page.waitForTimeout(2200)
  await page.screenshot({ path: `${outPrefix}-${d}m.png` })
}
await browser.close()

if (errors.length) {
  console.error('Console errors:\n' + errors.join('\n'))
  process.exit(1)
}
console.log('OK')

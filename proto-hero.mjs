import { chromium } from 'playwright'
const b = await chromium.launch()
const p = await (await b.newContext()).newPage()
const url = 'file://' + process.cwd() + '/dist/index.html'
await p.setViewportSize({ width: 1280, height: 800 })
await p.goto(url, { waitUntil: 'load' })
await p.evaluate(() => document.fonts.ready)
await p.waitForTimeout(900)

const m = await p.evaluate(() => {
  const r = el => { const b = el.getBoundingClientRect(); return { top: Math.round(b.top), bottom: Math.round(b.bottom) } }
  const header = document.querySelector('header')
  const row = header.querySelector('.row')
  const about = document.querySelector('#about')
  const cs = getComputedStyle(header)
  return {
    vh: window.innerHeight,
    navBottom: Math.round(document.querySelector('.section-nav').getBoundingClientRect().bottom),
    headerBox: r(header),
    heroContent: r(row),
    aboutTop: Math.round(about.getBoundingClientRect().top),
    borderBottom: cs.borderBottomWidth
  }
})
console.log(JSON.stringify(m, null, 0))
console.log('hero vertical center:', Math.round((m.heroContent.top + m.heroContent.bottom) / 2), 'viewport center:', Math.round(m.vh / 2))
console.log('about visible on first screen?', m.aboutTop < m.vh ? 'YES (peeks)' : 'no')

await p.screenshot({ path: 'hero-top.png' })
await b.close()
console.log('hero shot done')

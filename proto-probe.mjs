import { chromium } from 'playwright'
const b = await chromium.launch()
const p = await (await b.newContext()).newPage()
const url = 'file://' + process.cwd() + '/dist/index.html'
await p.setViewportSize({ width: 1280, height: 800 })
await p.goto(url, { waitUntil: 'load' })
await p.evaluate(() => document.fonts.ready)
await p.waitForTimeout(900)

const tops = await p.evaluate(() =>
  [...document.querySelectorAll('header, .cv-section')].map(s => Math.round(s.getBoundingClientRect().top + window.scrollY)))
console.log('section tops:', JSON.stringify(tops), 'startY', Math.round(await p.evaluate(() => window.scrollY)))

// single-gesture landings
const down = []
for (let i = 0; i < 5; i++) { await p.mouse.wheel(0, 400); await p.waitForTimeout(900); down.push(Math.round(await p.evaluate(() => window.scrollY))) }
console.log('single wheel down:', JSON.stringify(down))

// back to top
await p.evaluate(() => window.scrollTo(0, 0)); await p.waitForTimeout(700)

// BURST: many rapid wheel events (approximates a hard flick — should still advance exactly ONE section)
for (let i = 0; i < 20; i++) { await p.mouse.wheel(0, 150) }
await p.waitForTimeout(1200)
const burstY = Math.round(await p.evaluate(() => window.scrollY))
const onSection = tops.some(t => Math.abs(t - burstY) <= 2)
console.log('burst landing:', burstY, '| on a section top?', onSection, '| == About('+tops[1]+')?', Math.abs(burstY - tops[1]) <= 2)

// OVERLAY: go to experience, open a card, close it — position must be preserved (centred)
const expIdx = await p.evaluate(() => [...document.querySelectorAll('header, .cv-section')].findIndex(s => s.id === 'experience'))
await p.evaluate(i => { const t = [...document.querySelectorAll('header, .cv-section')]; window.scrollTo(0, Math.round(t[i].getBoundingClientRect().top + window.scrollY)) }, expIdx)
await p.waitForTimeout(500)
const beforeOpen = Math.round(await p.evaluate(() => window.scrollY))
await p.evaluate(() => { location.hash = 'p1' }); await p.waitForTimeout(400)   // open card
await p.evaluate(() => { location.hash = 'experience' }); await p.waitForTimeout(500) // close (as the link/Esc do)
const afterClose = Math.round(await p.evaluate(() => window.scrollY))
console.log('overlay: experienceTop', tops[expIdx], '| beforeOpen', beforeOpen, '| afterClose', afterClose, '| drift', afterClose - beforeOpen)

await b.close()
console.log('probe done')

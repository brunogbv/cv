import { chromium } from 'playwright'
const b = await chromium.launch()
const p = await (await b.newContext()).newPage()
const url = 'file://' + process.cwd() + '/dist/index.html'
await p.setViewportSize({ width: 1280, height: 720 })
await p.goto(url, { waitUntil: 'load' })
await p.evaluate(() => document.fonts.ready)
await p.waitForTimeout(1000)

const info = await p.evaluate(() => {
  const y = window.scrollY
  const tops = [...document.querySelectorAll('header, .cv-section')]
    .map(s => ({ id: s.id || 'header', top: Math.round(s.getBoundingClientRect().top + window.scrollY), h: Math.round(s.getBoundingClientRect().height) }))
  return { startY: y, vh: window.innerHeight, tops }
})
console.log('viewport', info.vh, 'startY', info.startY)
console.log('sections', info.tops.map(t => `${t.id}@${t.top}(h${t.h})`).join('  '))

// wheel down through the whole deck
const down = []
for (let i = 0; i < 6; i++) {
  await p.mouse.wheel(0, 400)
  await p.waitForTimeout(950)
  down.push(Math.round(await p.evaluate(() => window.scrollY)))
}
console.log('wheel down landings:', JSON.stringify(down))

// wheel up back
const up = []
for (let i = 0; i < 6; i++) {
  await p.mouse.wheel(0, -400)
  await p.waitForTimeout(950)
  up.push(Math.round(await p.evaluate(() => window.scrollY)))
}
console.log('wheel up landings:  ', JSON.stringify(up))

const tail = await p.evaluate(() => ({
  scrollHeight: Math.round(document.scrollingElement.scrollHeight),
  vh: window.innerHeight,
  maxScroll: Math.round(document.scrollingElement.scrollHeight - window.innerHeight),
  lastTop: Math.round([...document.querySelectorAll('header, .cv-section')].pop().getBoundingClientRect().top + window.scrollY)
}))
console.log('trailing check: maxScroll', tail.maxScroll, 'lastSectionTop', tail.lastTop, '=> gap', tail.maxScroll - tail.lastTop)

await b.close()
console.log('probe done')

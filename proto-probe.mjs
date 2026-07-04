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
const onTop = y => tops.some(t => Math.abs(t - y) <= 3)
console.log('section tops:', JSON.stringify(tops), 'startY', Math.round(await p.evaluate(() => window.scrollY)))

// keyboard: one ArrowDown press = one section (via scrollIntoView + snap)
const keys = []
for (let i = 0; i < 5; i++) { await p.keyboard.press('ArrowDown'); await p.waitForTimeout(700); keys.push(Math.round(await p.evaluate(() => window.scrollY))) }
console.log('ArrowDown landings:', JSON.stringify(keys), '| all on a section?', keys.every(onTop))
const ups = []
for (let i = 0; i < 3; i++) { await p.keyboard.press('ArrowUp'); await p.waitForTimeout(700); ups.push(Math.round(await p.evaluate(() => window.scrollY))) }
console.log('ArrowUp landings:  ', JSON.stringify(ups), '| all on a section?', ups.every(onTop))

// native wheel + snap: a scroll should REST on a snap point (never between)
await p.evaluate(() => window.scrollTo(0, 0)); await p.waitForTimeout(600)
await p.mouse.wheel(0, 500); await p.waitForTimeout(900)
const wy = Math.round(await p.evaluate(() => window.scrollY))
console.log('after one wheel down:', wy, '| resting on a section?', onTop(wy))

// overlay open -> close preserves centred position
const expIdx = tops.findIndex((_, i) => i >= 0) // placeholder
const eIdx = await p.evaluate(() => [...document.querySelectorAll('header, .cv-section')].findIndex(s => s.id === 'experience'))
await p.evaluate(i => document.querySelectorAll('header, .cv-section')[i].scrollIntoView(), eIdx)
await p.waitForTimeout(700)
const before = Math.round(await p.evaluate(() => window.scrollY))
await p.evaluate(() => { location.hash = 'p1' }); await p.waitForTimeout(400)
await p.evaluate(() => { location.hash = 'experience' }); await p.waitForTimeout(700)
const after = Math.round(await p.evaluate(() => window.scrollY))
console.log('overlay: expTop', tops[eIdx], '| before', before, '| afterClose', after, '| drift', after - before)

await b.close()
console.log('probe done')

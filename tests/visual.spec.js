const { test, expect } = require('@playwright/test')

// One representative width per Bootstrap 5 breakpoint (xs/sm/md/lg/xl/xxl).
const BREAKPOINTS = [
  { name: 'xs-375', width: 375 },
  { name: 'sm-576', width: 576 },
  { name: 'md-768', width: 768 },
  { name: 'lg-992', width: 992 },
  { name: 'xl-1200', width: 1200 },
  { name: 'xxl-1440', width: 1440 }
]

for (const bp of BREAKPOINTS) {
  test(`CV page renders at ${bp.name}`, async ({ page }) => {
    await page.setViewportSize({ width: bp.width, height: 900 })
    await page.goto('index.html')
    // page.evaluate awaits a returned promise, so this blocks until webfonts have loaded.
    await page.evaluate(() => document.fonts.ready)
    // Pin each rail's resting scroll position so the snapshot is deterministic — snap containers
    // otherwise re-snap / restore a prior position (research D6). reducedMotion:'reduce' (config)
    // already makes this instant (no smooth-scroll glide).
    await page.evaluate(() => {
      history.scrollRestoration = 'manual'
      document.querySelectorAll('.cv-rail').forEach((rail) => { rail.scrollLeft = 0 })
      document.querySelectorAll('.cv-rail-item').forEach((card) => { card.scrollTop = 0 })
    })
    await expect(page).toHaveScreenshot(`cv-${bp.name}.png`, { fullPage: true })
  })
}

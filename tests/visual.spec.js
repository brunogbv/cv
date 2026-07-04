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
    // Deck determinism: the full-viewport snap deck must be captured from a fixed resting state.
    // Pin scroll to the top (the hero) and disable scroll restoration so the fullPage capture is
    // stable regardless of any prior scroll position.
    await page.evaluate(() => {
      history.scrollRestoration = 'manual'
      window.scrollTo(0, 0)
    })
    await expect(page).toHaveScreenshot(`cv-${bp.name}.png`, { fullPage: true })
  })
}

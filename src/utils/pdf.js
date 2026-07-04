const { chromium } = require('playwright')

module.exports = async function buildPdf (inputFile, outputFile) {
  const browser = await chromium.launch({
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage']
  })
  try {
    const page = await browser.newPage()
    // Force PRINT media BEFORE navigating so the PDF is the clean linear document regardless of any
    // screen-only presentation layer: `@media not print` rules (the editorial deck/restyle) are
    // excluded, and screen-only assets like the `media="screen"` editorial webfonts are never even
    // fetched — so the PDF renders in Roboto, pixel-identical to before the screen redesign. Relying on
    // page.pdf()'s default print emulation proved insufficient (screen fonts loaded during navigation
    // still perturbed the render); emulating before goto is what actually isolates the print output.
    await page.emulateMedia({ media: 'print' })
    // Assets are vendored locally (issue #24), so 'load' is sufficient and the explicit timeout
    // makes a missing/slow resource fail fast instead of hanging.
    await page.goto(`file://${inputFile}`, {
      waitUntil: 'load',
      timeout: 30000
    })
    // Ensure the vendored web fonts are parsed and applied before rendering so the PDF never falls
    // back to default fonts. Bounded so a stalled font load fails the build instead of hanging.
    await page.evaluate(() => Promise.race([
      document.fonts.ready,
      new Promise((resolve, reject) => setTimeout(() => reject(new Error('fonts not ready within 10s')), 10000))
    ]).then(() => undefined))
    await page.pdf({
      path: outputFile,
      format: 'A4',
      margin: {
        top: '2.54cm',
        right: '2.54cm',
        bottom: '2.54cm',
        left: '2.54cm'
      }
    })
  } finally {
    // Always release the browser, even if navigation/render throws.
    await browser.close()
  }
}

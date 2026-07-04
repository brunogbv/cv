const { test, expect } = require('@playwright/test')
const fs = require('fs')
const path = require('path')

// PDF visual-regression gate: rasterise every page of the built PDF and diff each against a
// committed baseline, so a change to the PDF's content/layout fails a PR (tests/pdf.spec.js only
// checks the PDF is a valid, non-empty file). Baselines live under tests/__screenshots__/ next to
// the screen snapshots and are refreshed the same way — `make visual-update` (which passes
// --update-snapshots); a mismatched or missing baseline fails the gate (CI never updates).
//
// Determinism: rendered with mupdf (a pure-WASM PDF engine — no native binaries, no apt packages,
// identical output on any OS), at a fixed DPI, in fixed page order, and only ever in the pinned
// Playwright image. The build's "Last update" date is pinned via SOURCE_DATE_EPOCH (see the
// Makefile visual targets and build.js) so the date text baked into the PDF is stable day-to-day.

// Rasterise at 150 DPI. High enough to catch layout/glyph regressions, low enough to keep baseline
// PNGs and diff cost modest. PDF user space is 72 units/inch, so the render scale is 150/72.
const DPI = 150

// Tolerance. mupdf is byte-deterministic (same PDF → identical pixels, verified: zero differing
// subpixels across re-renders), and both baseline and run are produced only in the pinned image, so
// there is no legitimate render noise to absorb — unlike the browser screenshots, whose 0.01 ratio
// covers anti-aliasing/font-hinting variance. We therefore require an *exact* pixel match
// (maxDiffPixels: 0): a one-line text edit changes only ~0.001 of a page, well under the screen
// gate's 0.01 ratio, so a loose ratio would let real PDF content changes slip through. `threshold`
// is the per-pixel colour-distance below which two pixels count as equal (kept at the screen value).
const MATCH_OPTIONS = { maxDiffPixels: 0, threshold: 0.2 }

test('PDF pages match their visual baselines', async () => {
  const distDir = path.join(__dirname, '..', 'dist')
  // Sort so the pick is deterministic regardless of directory-entry order.
  const pdfs = fs.readdirSync(distDir).filter((f) => f.endsWith('.pdf')).sort()
  expect(pdfs, 'a PDF is generated into dist/').not.toHaveLength(0)

  const pdfPath = path.join(distDir, pdfs[0])
  const buffer = fs.readFileSync(pdfPath)

  // mupdf is ESM-only; load it dynamically from this CommonJS spec.
  const mupdf = await import('mupdf')
  const doc = mupdf.Document.openDocument(buffer, 'application/pdf')
  const pageCount = doc.countPages()
  expect(pageCount, 'PDF has at least one page').toBeGreaterThan(0)

  const scale = DPI / 72
  const matrix = mupdf.Matrix.scale(scale, scale)

  for (let i = 0; i < pageCount; i++) {
    const page = doc.loadPage(i)
    // DeviceRGB + alpha:false → an opaque RGB pixmap; no alpha channel to vary between renders.
    const pixmap = page.toPixmap(matrix, mupdf.ColorSpace.DeviceRGB, false)
    const png = Buffer.from(pixmap.asPNG())
    // Free the WASM allocations eagerly rather than waiting on GC finalization.
    pixmap.destroy()
    page.destroy()
    // 1-based, zero-padded so names sort correctly (pdf-page-01, …, pdf-page-10).
    const name = `pdf-page-${String(i + 1).padStart(2, '0')}.png`
    expect(png).toMatchSnapshot(name, MATCH_OPTIONS)
  }
  doc.destroy()

  // Guard against a page-count change leaving an orphaned baseline (which no per-page assertion
  // above would ever compare against). Only checked on a normal run — during --update-snapshots the
  // baseline dir is being (re)written, so stale files are expected until the run finishes.
  if (!isUpdatingSnapshots()) {
    const baselineDir = path.join(__dirname, '__screenshots__', 'pdf-visual.spec.js')
    const baselines = fs.existsSync(baselineDir)
      ? fs.readdirSync(baselineDir).filter((f) => /^pdf-page-\d+\.png$/.test(f))
      : []
    expect(baselines.length, 'one committed baseline per rendered PDF page').toBe(pageCount)
  }
})

// True when the run was invoked with --update-snapshots / -u (what `make visual-update` passes).
// Detected from argv — unambiguous and stable across Playwright versions (the config field has been
// renamed between releases). During an update run the baseline dir is mid-rewrite, so the orphan
// check above is skipped. `-u` is Playwright's documented short alias, so both forms are handled.
function isUpdatingSnapshots () {
  return process.argv.some((a) =>
    a === '--update-snapshots' || a.startsWith('--update-snapshots=') ||
    a === '-u' || a.startsWith('-u='))
}

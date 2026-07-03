const { test, expect } = require('@playwright/test')
const fs = require('fs')
const path = require('path')

// Guards the PDF half of the build: `make page` must produce a valid, non-empty PDF.
test('build produces a valid PDF', () => {
  const distDir = path.join(__dirname, '..', 'dist')
  const pdfs = fs.readdirSync(distDir).filter((f) => f.endsWith('.pdf'))
  expect(pdfs, 'a PDF is generated into dist/').not.toHaveLength(0)

  const pdfPath = path.join(distDir, pdfs[0])
  expect(fs.statSync(pdfPath).size, 'PDF is non-trivial').toBeGreaterThan(1024)

  const header = fs.readFileSync(pdfPath).subarray(0, 5).toString('latin1')
  expect(header, 'valid PDF magic header').toBe('%PDF-')
})

const path = require('path')
const { defineConfig } = require('@playwright/test')

// The built site is loaded straight from disk (same as src/utils/pdf.js) — no server needed.
const distDir = path.join(__dirname, 'dist')

module.exports = defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  reporter: process.env.CI ? [['html', { open: 'never' }], ['list']] : 'list',
  // Platform-neutral baseline names (no -darwin/-linux suffix): baselines are generated only in the
  // Linux Dev Container / CI, so a stray host run can't create a divergent variant.
  snapshotPathTemplate: '{testDir}/__screenshots__/{testFileName}/{arg}{ext}',
  use: {
    baseURL: `file://${distDir}/`,
    reducedMotion: 'reduce'
  },
  expect: {
    toHaveScreenshot: {
      maxDiffPixelRatio: 0.01,
      threshold: 0.2,
      animations: 'disabled',
      // Force scroll-reveal elements to their final state so captures are deterministic.
      stylePath: path.join(__dirname, 'tests', 'snapshot.css')
    }
  }
})

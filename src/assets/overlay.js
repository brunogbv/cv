// Detail-overlay dialog a11y (US2) — SCREEN-ONLY progressive enhancement, layered on the CSS
// `:target` baseline.
//
// Open/close, scroll-lock, and the backdrop are all handled by native CSS `:target` (a summary card
// is `<a href="#e0">`, the overlay is `<div id="e0" class="cv-detail">`, closing is a link back to
// the section, e.g. `#experience`) — NO JavaScript required, and that baseline is what PDF generation
// renders (the overlays are screen-only). This
// script only ADDS dialog semantics on top when JS runs: it moves focus into the opened overlay,
// traps Tab within the overlay, closes on Escape, and returns focus to the trigger on close. It is a
// strict enhancement — with no JS the `:target` overlay still opens and closes, and during PDF
// generation (no keys pressed, no hash) this is a harmless no-op. Every DOM access is guarded so a
// missing element never throws.
//
// Note: we deliberately do NOT mark the background `inert`. The overlays render *inside*
// `.container.page`, and `inert` propagates to descendants and can't be lifted on one — so inerting
// an ancestor would freeze the open overlay itself (dead scroller, unclickable backdrop) in browsers
// that support `inert`. The modal is already scoped by `aria-modal="true"`, the viewport-covering
// backdrop, and the Tab-trap below, so ancestor-inert is both harmful here and redundant.
(function () {
  const FOCUSABLE = 'a[href], button, input, textarea, select, [tabindex]:not([tabindex="-1"])'

  let trigger = null

  // The currently-open detail overlay (matched by :target), or null. Section-agnostic — overlays
  // live in Skills/Experience/Additional/Competitions with ids like sk0 / e0 / x0 / c0.
  const openOverlay = () => document.querySelector('.cv-detail:target')

  const focusables = (overlay) => {
    return Array.prototype.slice
      .call(overlay.querySelectorAll(FOCUSABLE))
      .filter((el) => el.offsetParent !== null && el.tabIndex >= 0)
  }

  const onHashChange = () => {
    const overlay = openOverlay()
    if (overlay) {
      // Remember what to restore focus to only on the first activation of a session.
      if (!trigger) trigger = document.activeElement
      // preventScroll: the overlay is a fixed full-screen layer — moving focus into it must not
      // scroll the deck behind it.
      const targets = focusables(overlay)
      if (targets.length) {
        targets[0].focus({ preventScroll: true })
      } else {
        overlay.setAttribute('tabindex', '-1')
        overlay.focus({ preventScroll: true })
      }
    } else {
      // preventScroll: restoring focus to the triggering card must not yank the deck to it (that
      // was the "page jumps after close" bug).
      if (trigger && typeof trigger.focus === 'function') trigger.focus({ preventScroll: true })
      trigger = null
    }
  }

  const onKeydown = (e) => {
    const overlay = openOverlay()
    if (!overlay) return

    if (e.key === 'Escape') {
      e.preventDefault()
      // Close to the overlay's own section (Experience / Additional / Competitions).
      const section = overlay.closest('.cv-section')
      window.location.hash = section ? section.id : ''
      return
    }

    if (e.key === 'Tab') {
      const targets = focusables(overlay)
      if (!targets.length) {
        // Nothing focusable inside — keep focus pinned to the overlay itself.
        e.preventDefault()
        overlay.focus()
        return
      }
      const first = targets[0]
      const last = targets[targets.length - 1]
      const active = document.activeElement
      if (e.shiftKey && (active === first || active === overlay)) {
        e.preventDefault()
        last.focus()
      } else if (!e.shiftKey && active === last) {
        e.preventDefault()
        first.focus()
      }
    }
  }

  const setup = () => {
    try {
      // No overlays on the page → nothing to enhance.
      if (!document.querySelector('.cv-detail')) return
      window.addEventListener('hashchange', onHashChange)
      document.addEventListener('keydown', onKeydown)
      // Handle a deep link that lands already on an overlay.
      onHashChange()
    } catch {
      // A strict enhancement: if wiring fails, the `:target` baseline still works.
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', setup)
  } else {
    setup()
  }
})()

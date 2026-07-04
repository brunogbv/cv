// Deck keyboard navigation (US1) — progressive enhancement, screen-only effect.
//
// The full-viewport "deck" is scrolled by NATIVE CSS Scroll Snap (styles.css): the browser owns
// wheel / trackpad / touch momentum and rests on a section. We deliberately do NOT intercept
// wheel/touch (a hand-rolled scroll-jacker fights native trackpad momentum — see
// docs/interaction-gotchas.md). This script only makes the KEYBOARD move exactly one section per
// Arrow/Page press via the browser's own smooth scroll (scrollIntoView), which coexists with snap.
//
// Fail-safe: with no JavaScript, native snap + the browser's native keyboard scrolling still work;
// this only upgrades key presses to one-section-per-press. In print there is no keyboard scrolling,
// and the deck layout itself is screen-only (styles.css @media not print), so this never affects the PDF.
(function () {
  var reduce = window.matchMedia('(prefers-reduced-motion: reduce)')

  function isField (t) {
    var n = (t && t.tagName || '').toLowerCase()
    return n === 'input' || n === 'textarea' || n === 'select'
  }

  function sections () {
    return [].slice.call(document.querySelectorAll('header, .cv-section'))
  }

  // The section we're resting on = the one whose top is nearest the top of the viewport.
  function currentIndex () {
    var els = sections()
    var best = 0
    var bestDist = Infinity
    for (var i = 0; i < els.length; i++) {
      var d = Math.abs(els[i].getBoundingClientRect().top)
      if (d < bestDist) { bestDist = d; best = i }
    }
    return best
  }

  document.addEventListener('keydown', function (e) {
    if (isField(e.target) || e.repeat) return // ignore auto-repeat: one press = one section
    var dir = (e.key === 'ArrowDown' || e.key === 'PageDown') ? 1 : (e.key === 'ArrowUp' || e.key === 'PageUp') ? -1 : 0
    if (!dir) return
    var els = sections()
    var target = currentIndex() + dir
    if (target < 0 || target >= els.length) return
    e.preventDefault()
    els[target].scrollIntoView({ behavior: reduce.matches ? 'auto' : 'smooth', block: 'start' })
  })
})()

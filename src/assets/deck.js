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
  const reduce = window.matchMedia('(prefers-reduced-motion: reduce)')

  function isField (t) {
    const n = ((t && t.tagName) || '').toLowerCase()
    return n === 'input' || n === 'textarea' || n === 'select'
  }

  function sections () {
    return [].slice.call(document.querySelectorAll('header, .cv-section'))
  }

  // The section we're resting on = the one whose top is nearest the top of the viewport.
  function currentIndex () {
    const els = sections()
    let best = 0
    let bestDist = Infinity
    for (let i = 0; i < els.length; i++) {
      const d = Math.abs(els[i].getBoundingClientRect().top)
      if (d < bestDist) { bestDist = d; best = i }
    }
    return best
  }

  document.addEventListener('keydown', function (e) {
    if (isField(e.target) || e.repeat) return // ignore auto-repeat: one press = one section
    const dir = (e.key === 'ArrowDown' || e.key === 'PageDown') ? 1 : (e.key === 'ArrowUp' || e.key === 'PageUp') ? -1 : 0
    if (!dir) return
    const els = sections()
    const target = currentIndex() + dir
    if (target < 0 || target >= els.length) return
    e.preventDefault()
    els[target].scrollIntoView({ behavior: reduce.matches ? 'auto' : 'smooth', block: 'start' })
  })

  // Through-Line signature (US5): reflect the active section on the left-gutter progress spine.
  // Screen-only progressive enhancement — with no JS the spine is a static index of jump links.
  // deck.js loads in <head>, so defer DOM queries until the body exists (mirrors reveal.js).
  const initThroughLine = () => {
    const line = document.querySelector('.through-line')
    if (!line) return
    const nodes = [].slice.call(line.querySelectorAll('a[data-section]'))
    if (!nodes.length) return
    // Panels = the hero (header) followed by each node's section. The nearest-centred panel decides
    // the active node; while the hero is centred no node is active yet (active = -1, empty fill).
    const panels = [document.querySelector('header')].concat(nodes.map((n) => document.getElementById(n.dataset.section)))
    const status = line.querySelector('.tl-status')
    let ticking = false
    const paint = () => {
      ticking = false
      const mid = window.innerHeight / 2
      let nearest = 0
      let best = Infinity
      for (let i = 0; i < panels.length; i++) {
        if (!panels[i]) continue
        const r = panels[i].getBoundingClientRect()
        const d = Math.abs((r.top + r.bottom) / 2 - mid)
        if (d < best) { best = d; nearest = i }
      }
      const active = nearest - 1 // -1 on the hero; 0..n-1 once a section is centred
      line.style.setProperty('--tl-progress', (active >= 0 && nodes.length > 1) ? active / (nodes.length - 1) : 0)
      for (let i = 0; i < nodes.length; i++) {
        nodes[i].classList.toggle('is-past', i < active)
        nodes[i].classList.toggle('is-active', i === active)
        if (i === active) nodes[i].setAttribute('aria-current', 'true')
        else nodes[i].removeAttribute('aria-current')
      }
      if (status) {
        status.textContent = (active >= 0) ? ('Section ' + (active + 1) + ' of ' + nodes.length + ': ' + (nodes[active].dataset.label || '')) : ''
      }
    }
    const onScroll = () => {
      if (!ticking) {
        ticking = true
        window.requestAnimationFrame(paint)
      }
    }
    window.addEventListener('scroll', onScroll, { passive: true })
    window.addEventListener('resize', onScroll, { passive: true })
    paint()
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initThroughLine)
  } else {
    initThroughLine()
  }
})()

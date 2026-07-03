/* global IntersectionObserver */
// Scroll reveal (US3) — progressive enhancement, loaded synchronously from <head>.
//
// Adding `.js` to the root element BEFORE first paint lets styles.css hold `.reveal` elements hidden
// until they scroll into view (no flash of pre-revealed content). A one-shot IntersectionObserver then
// marks each element `.is-visible` as it enters the viewport. The enhancement is designed to FAIL
// VISIBLE: with no JavaScript `.js` is never set and content stays fully visible; if the observer is
// unavailable or setup throws for any reason, every `.reveal` is revealed immediately. Motion is also
// disabled for reduced-motion users and in print (see styles.css), so this only ever adds a subtle
// on-screen entrance.
document.documentElement.classList.add('js')

const revealAll = () => {
  document.querySelectorAll('.reveal').forEach((el) => el.classList.add('is-visible'))
}

const setup = () => {
  try {
    const reveals = document.querySelectorAll('.reveal')
    if (!reveals.length || !('IntersectionObserver' in window)) {
      revealAll()
      return
    }

    const observer = new IntersectionObserver((entries, obs) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return
        entry.target.classList.add('is-visible')
        obs.unobserve(entry.target)
      })
    })

    reveals.forEach((el) => observer.observe(el))
  } catch {
    // Never leave content stuck hidden if observer setup fails for any reason.
    revealAll()
  }
}

// The script runs in <head>, so wait for the body before querying for `.reveal` elements.
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', setup)
} else {
  setup()
}

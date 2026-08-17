/* web-landing/script.js — tiny, dependency-free page behavior.
 *
 * 1. Custom cursor: 6px green dot at the pointer + a trailing ring that lags
 *    behind (rAF lerp). Native cursor is kept visible for usability;
 *    touch devices and reduced-motion get no overlay.
 * 2. Phone mockup: a scripted ~12s loop of the Timeline "in action" —
 *    habit cards complete one-by-one, streak ticks 37→40, XP fills,
 *    level-up toast appears, then the loop resets. */

(function () {
  "use strict";

  const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  /* ── 1. Custom cursor ─────────────────────────────────────────────── */
  const finePointer = window.matchMedia("(pointer: fine)").matches;
  const dot = document.querySelector(".cursor-dot");
  const ring = document.querySelector(".cursor-ring");

  if (finePointer && dot && ring) {
    let mx = -100, my = -100, rx = -100, ry = -100, raf = null;

    const place = (el, x, y) => {
      el.style.transform = `translate3d(${x}px, ${y}px, 0) translate(-50%, -50%)`;
    };

    window.addEventListener(
      "mousemove",
      (e) => {
        mx = e.clientX;
        my = e.clientY;
        place(dot, mx, my);
        if (!document.body.classList.contains("cursor-visible")) {
          document.body.classList.add("cursor-visible");
        }
        if (raf === null) raf = requestAnimationFrame(loop);
      },
      { passive: true },
    );

    function loop() {
      // Reduced motion: keep the dot, drop the trailing animation entirely.
      if (reduced) {
        raf = null;
        return;
      }
      rx += (mx - rx) * 0.22;
      ry += (my - ry) * 0.22;
      place(ring, rx, ry);
      raf = requestAnimationFrame(loop);
    }

    document.querySelectorAll("a, button, summary").forEach((el) => {
      el.addEventListener("mouseenter", () => ring.classList.add("is-hover"));
      el.addEventListener("mouseleave", () => ring.classList.remove("is-hover"));
    });
  }

  /* ── 2. Phone mockup timeline loop ─────────────────────────────────── */
  const phone = document.getElementById("phone-mockup");
  if (phone) {
    const cards = phone.querySelectorAll(".habit-card");
    const streak = phone.querySelector(".screen-streak");
    const xpFill = phone.querySelector(".xp-fill");
    const xpNum = phone.querySelector(".xp-num");
    const toast = phone.querySelector(".level-toast");
    const XP_TEXT = ["960", "1,070", "1,190", "1,400"];

    // phase: 0 = fresh day, 1..3 = first N cards completed. 3 is the
    // "level up" beat (full XP + toast), then it resets to 0.
    const apply = (phase) => {
      cards.forEach((card, i) => card.classList.toggle("done", i < phase));
      if (streak) streak.textContent = `🔥 ${37 + Math.min(phase, 3)}`;
      if (xpFill) xpFill.style.width = `${25 + phase * 25}%`;
      if (xpNum) xpNum.textContent = `${XP_TEXT[phase]} / 1,400 XP`;
      if (toast) toast.classList.toggle("visible", phase === 3);
    };

    if (reduced) {
      // Static, composed frame: one habit done, sensible resting state.
      apply(1);
      return;
    }

    let phase = 0;
    const WAIT = [2400, 2400, 2600, 4400]; // ms per phase → ~12s loop

    const tick = () => {
      apply(phase);
      const wait = WAIT[phase];
      phase = (phase + 1) % 4;
      setTimeout(tick, wait);
    };
    tick();
  }
})();
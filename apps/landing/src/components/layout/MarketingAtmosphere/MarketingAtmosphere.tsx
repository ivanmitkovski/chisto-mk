"use client";

import { motion, useReducedMotion } from "framer-motion";

/** Stable % positions / motion params; avoids hydration drift. */
const AMBIENT_DOTS = [
  { left: 6.2, top: 8.4, s: 2, d: 20, delay: 0.3, tone: "p" as const },
  { left: 14.8, top: 22.1, s: 1.5, d: 16, delay: 1.2, tone: "g" as const },
  { left: 23.5, top: 11.2, s: 2.5, d: 22, delay: 0.8, tone: "p" as const },
  { left: 31.0, top: 38.6, s: 1.5, d: 18, delay: 2.1, tone: "g" as const },
  { left: 42.3, top: 6.8, s: 2, d: 14, delay: 0.5, tone: "p" as const },
  { left: 51.7, top: 19.4, s: 1.5, d: 24, delay: 1.8, tone: "g" as const },
  { left: 58.2, top: 44.0, s: 2, d: 17, delay: 0.2, tone: "p" as const },
  { left: 67.9, top: 12.6, s: 2.5, d: 21, delay: 2.4, tone: "p" as const },
  { left: 74.1, top: 31.5, s: 1.5, d: 19, delay: 1.0, tone: "g" as const },
  { left: 82.6, top: 8.9, s: 2, d: 15, delay: 0.7, tone: "p" as const },
  { left: 88.3, top: 26.2, s: 1.5, d: 23, delay: 1.5, tone: "g" as const },
  { left: 93.1, top: 48.0, s: 2, d: 18, delay: 0.9, tone: "p" as const },
  { left: 11.4, top: 55.8, s: 2.5, d: 20, delay: 2.0, tone: "g" as const },
  { left: 19.7, top: 72.3, s: 1.5, d: 16, delay: 0.4, tone: "p" as const },
  { left: 28.5, top: 61.0, s: 2, d: 22, delay: 1.3, tone: "g" as const },
  { left: 37.2, top: 78.5, s: 1.5, d: 14, delay: 2.2, tone: "p" as const },
  { left: 46.8, top: 58.2, s: 2.5, d: 24, delay: 0.6, tone: "p" as const },
  { left: 55.4, top: 88.1, s: 2, d: 17, delay: 1.7, tone: "g" as const },
  { left: 63.1, top: 66.4, s: 1.5, d: 21, delay: 0.1, tone: "p" as const },
  { left: 71.8, top: 82.0, s: 2, d: 19, delay: 1.1, tone: "g" as const },
  { left: 79.5, top: 54.3, s: 2.5, d: 15, delay: 2.3, tone: "p" as const },
  { left: 86.2, top: 71.8, s: 1.5, d: 23, delay: 0.8, tone: "g" as const },
  { left: 91.7, top: 92.4, s: 2, d: 18, delay: 1.4, tone: "p" as const },
  { left: 4.5, top: 42.0, s: 1.5, d: 20, delay: 1.9, tone: "g" as const },
  { left: 17.3, top: 88.7, s: 2, d: 16, delay: 0.5, tone: "p" as const },
  { left: 39.5, top: 14.8, s: 2.5, d: 22, delay: 2.5, tone: "g" as const },
  { left: 48.9, top: 95.2, s: 1.5, d: 14, delay: 0.0, tone: "p" as const },
  { left: 61.2, top: 36.8, s: 2, d: 24, delay: 1.6, tone: "g" as const },
  { left: 95.5, top: 63.5, s: 2.5, d: 17, delay: 0.3, tone: "g" as const },
] as const;

function toneClass(tone: "p" | "g") {
  return tone === "p" ? "bg-primary/25" : "bg-gray-400/18";
}

function AmbientParticles({ reducedMotion }: { reducedMotion: boolean }) {
  return (
    <div className="absolute inset-0 overflow-hidden opacity-[0.62]">
      {AMBIENT_DOTS.map((dot, i) => {
        if (reducedMotion) {
          return (
            <span
              key={i}
              className={`absolute rounded-full ${toneClass(dot.tone)}`}
              style={{
                left: `${dot.left}%`,
                top: `${dot.top}%`,
                width: dot.s,
                height: dot.s,
              }}
              aria-hidden
            />
          );
        }

        return (
          <motion.span
            key={i}
            className="absolute"
            style={{
              left: `${dot.left}%`,
              top: `${dot.top}%`,
              width: dot.s,
              height: dot.s,
            }}
            aria-hidden
            animate={{
              y: [0, -10, 0],
              opacity: [0.35, 0.62, 0.35],
            }}
            transition={{
              duration: dot.d,
              repeat: Infinity,
              ease: "easeInOut",
              delay: dot.delay,
            }}
          >
            <span
              className={`block size-full rounded-full ${toneClass(dot.tone)}`}
            />
          </motion.span>
        );
      })}
    </div>
  );
}

/** Large, heavily blurred cool orbs (read as distant / behind). */
function AmbientOrbsFar({ reducedMotion }: { reducedMotion: boolean }) {
  const far = [
    {
      className: "left-[-18%] top-[25%] h-[38rem] w-[38rem] bg-sky-300/25",
      d: 34,
      delay: 0,
    },
    {
      className: "right-[-14%] bottom-[5%] h-[34rem] w-[34rem] bg-slate-400/20",
      d: 40,
      delay: 2.4,
    },
  ] as const;

  return (
    <>
      {far.map((o, i) =>
        reducedMotion ? (
          <div
            key={i}
            className={`pointer-events-none absolute rounded-full blur-[140px] ${o.className}`}
          />
        ) : (
          <motion.div
            key={i}
            className={`pointer-events-none absolute rounded-full blur-[140px] ${o.className}`}
            animate={{
              scale: [1, 1.028, 1],
              opacity: [0.32, 0.48, 0.32],
            }}
            transition={{
              duration: o.d,
              repeat: Infinity,
              ease: "easeInOut",
              delay: o.delay,
            }}
          />
        ),
      )}
    </>
  );
}

/** Nearer brand-tinted orbs; slightly snappier motion than far layer. */
function AmbientOrbsNear({ reducedMotion }: { reducedMotion: boolean }) {
  const orbs = [
    { className: "left-[-12%] top-[18%] h-[28rem] w-[28rem] bg-primary/8", d: 22, delay: 0 },
    { className: "right-[-8%] top-[48%] h-[22rem] w-[22rem] bg-emerald-400/6", d: 19, delay: 1.2 },
    { className: "left-[35%] bottom-[-5%] h-[20rem] w-[20rem] bg-sky-400/5", d: 25, delay: 0.6 },
  ] as const;

  return (
    <>
      {orbs.map((o, i) =>
        reducedMotion ? (
          <div
            key={i}
            className={`pointer-events-none absolute rounded-full blur-[100px] ${o.className}`}
          />
        ) : (
          <motion.div
            key={i}
            className={`pointer-events-none absolute rounded-full blur-[100px] ${o.className}`}
            animate={{
              scale: [1, 1.075, 1],
              opacity: [0.58, 0.92, 0.58],
            }}
            transition={{
              duration: o.d,
              repeat: Infinity,
              ease: "easeInOut",
              delay: o.delay,
            }}
          />
        ),
      )}
    </>
  );
}

export function MarketingAtmosphere() {
  const reducedMotion = useReducedMotion() ?? false;

  return (
    <div
      className="pointer-events-none absolute inset-0 z-0 overflow-hidden"
      aria-hidden
    >
      <AmbientOrbsFar reducedMotion={reducedMotion} />
      <AmbientOrbsNear reducedMotion={reducedMotion} />
      <div className="absolute inset-0 grid-lines-fade opacity-[0.48]" />
      <div
        className="absolute inset-0 pattern-diagonal-soft opacity-[0.32] [mask-image:linear-gradient(to_bottom,transparent,black_8%,black_92%,transparent)] [-webkit-mask-image:linear-gradient(to_bottom,transparent,black_8%,black_92%,transparent)]"
        aria-hidden
      />
      <div
        className="absolute inset-0 pattern-dots-soft opacity-[0.22] [mask-image:linear-gradient(to_bottom,transparent,black_12%,black_88%,transparent)] [-webkit-mask-image:linear-gradient(to_bottom,transparent,black_12%,black_88%,transparent)]"
        aria-hidden
      />
      <div className="absolute inset-0 noise-overlay-soft opacity-[0.68]" />
      <div className="atmosphere-vignette absolute inset-0 opacity-[0.72]" />
      <AmbientParticles reducedMotion={reducedMotion} />
    </div>
  );
}

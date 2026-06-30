/** Decorative hero background layers — isolated for readability and mobile perf tuning. */
export function HeroAtmosphere() {
  return (
    <>
      <div
        className="pointer-events-none absolute inset-0 z-0 opacity-[0.55] mix-blend-multiply max-md:opacity-40"
        aria-hidden
      >
        <div className="absolute -left-[8%] top-[-12%] h-[min(78vw,38rem)] w-[min(78vw,38rem)] rounded-full bg-[radial-gradient(circle_at_40%_40%,rgba(0,217,142,0.2)_0%,rgba(0,217,142,0.06)_38%,transparent_68%)] blur-3xl md:opacity-90" />
        <div className="absolute -right-[6%] top-[0%] h-[min(70vw,34rem)] w-[min(70vw,34rem)] rounded-full bg-[radial-gradient(circle_at_55%_45%,rgba(125,211,252,0.18)_0%,rgba(125,211,252,0.05)_40%,transparent_68%)] blur-3xl md:opacity-95" />
        <div className="absolute bottom-[-8%] left-1/2 h-[min(85vw,42rem)] w-[min(115%,52rem)] -translate-x-1/2 rounded-full bg-[radial-gradient(ellipse_50%_42%_at_50%_40%,rgba(0,217,142,0.11)_0%,transparent_72%)] blur-3xl" />
      </div>
      <div
        className="pointer-events-none absolute inset-0 z-[1] pattern-dots-soft opacity-[0.2] mix-blend-multiply [mask-image:radial-gradient(ellipse_96%_82%_at_50%_38%,black_18%,transparent_74%)] [-webkit-mask-image:radial-gradient(ellipse_96%_82%_at_50%_38%,black_18%,transparent_74%)] max-md:opacity-[0.12]"
        aria-hidden
      />
      {/* Mobile: skip heavy depth layers to reduce paint cost */}
      <div
        className="pointer-events-none absolute inset-0 z-[1] mesh-hero-depth-clouds opacity-[0.32] max-md:hidden md:opacity-[0.38]"
        aria-hidden
      />
      <div
        className="pointer-events-none absolute inset-0 z-[1] mesh-hero-depth-lines opacity-[0.45] max-md:hidden md:opacity-[0.5]"
        aria-hidden
      />
      <div
        className="pointer-events-none absolute inset-0 z-[1] mesh-hero-depth-particles opacity-[0.55] max-md:hidden md:opacity-[0.62]"
        aria-hidden
      />
      <div className="pointer-events-none absolute inset-0 z-[1] noise-overlay-soft opacity-[0.38] max-md:opacity-[0.22]" aria-hidden />
      <div
        className="pointer-events-none absolute inset-0 z-[1] bg-[radial-gradient(ellipse_100%_78%_at_50%_42%,rgba(255,255,255,0.06)_0%,transparent_52%)] [mask-image:radial-gradient(ellipse_95%_85%_at_50%_40%,transparent_35%,black_100%)] [-webkit-mask-image:radial-gradient(ellipse_95%_85%_at_50%_40%,transparent_35%,black_100%)]"
        aria-hidden
      />
      <div
        className="pointer-events-none absolute inset-x-0 top-0 z-[1] h-px bg-gradient-to-r from-transparent via-black/[0.06] to-transparent"
        aria-hidden
      />
      <div className="pointer-events-none absolute inset-0 z-[12] mesh-hero-field-grid opacity-80 max-md:opacity-50" aria-hidden />
    </>
  );
}

export function HeroWaveFooter() {
  return (
    <>
      <div
        className="pointer-events-none absolute inset-x-0 bottom-0 z-[14] h-24 bg-gradient-to-b from-transparent via-white/14 to-[#f8fafc] sm:h-28 md:h-36 md:via-white/18 lg:h-[10.5rem] max-md:via-white/8"
        aria-hidden
      />
      <div className="pointer-events-none absolute inset-x-0 bottom-0 z-[15]" aria-hidden>
        <svg
          className="block h-12 w-full md:h-16 lg:h-[4.25rem] [shape-rendering:geometricPrecision]"
          viewBox="0 0 1440 72"
          preserveAspectRatio="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <defs>
            <linearGradient id="heroWaveFill" x1="0" y1="0" x2="0" y2="1" gradientUnits="objectBoundingBox">
              <stop offset="0%" stopColor="#e6e8ec" />
              <stop offset="38%" stopColor="#f2f3f5" />
              <stop offset="100%" stopColor="#f8fafc" />
            </linearGradient>
            <filter
              id="heroWaveEdgeSoft"
              x="-15%"
              y="-70%"
              width="130%"
              height="200%"
              colorInterpolationFilters="sRGB"
            >
              <feGaussianBlur in="SourceGraphic" stdDeviation="2.5" />
            </filter>
          </defs>
          <path
            fill="#ffffff"
            d="M0 72V42c120-18 280-18 400-6 160 16 320 16 480 0 140-14 360-20 560 8v28H0z"
            filter="url(#heroWaveEdgeSoft)"
            opacity={0.28}
            transform="translate(0 -2)"
          />
          <path fill="url(#heroWaveFill)" d="M0 72V42c120-18 280-18 400-6 160 16 320 16 480 0 140-14 360-20 560 8v28H0z" />
        </svg>
      </div>
    </>
  );
}

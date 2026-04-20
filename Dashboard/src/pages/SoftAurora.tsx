import React, { useEffect, useMemo, useRef } from 'react';
import './SoftAurora.css';

type SoftAuroraProps = {
  speed?: number;
  scale?: number;
  brightness?: number;
  color1?: string;
  color2?: string;
  noiseFrequency?: number;
  noiseAmplitude?: number;
  bandHeight?: number;
  bandSpread?: number;
  octaveDecay?: number;
  layerOffset?: number;
  colorSpeed?: number;
  enableMouseInteraction?: boolean;
  mouseInfluence?: number;
};

type Rgb = { r: number; g: number; b: number };

const clamp01 = (v: number) => Math.min(1, Math.max(0, v));

const hexToRgb = (hex: string): Rgb => {
  const raw = hex.trim().replace('#', '');
  const full = raw.length === 3 ? raw.split('').map(c => c + c).join('') : raw;
  const n = Number.parseInt(full, 16);
  if (!Number.isFinite(n) || full.length !== 6) return { r: 255, g: 255, b: 255 };
  return {
    r: (n >> 16) & 255,
    g: (n >> 8) & 255,
    b: n & 255
  };
};

const lerp = (a: number, b: number, t: number) => a + (b - a) * t;

// Small, fast value-noise (no deps) + FBM.
const hash2 = (x: number, y: number) => {
  const s = Math.sin(x * 127.1 + y * 311.7) * 43758.5453123;
  return s - Math.floor(s);
};

const valueNoise2 = (x: number, y: number) => {
  const xi = Math.floor(x);
  const yi = Math.floor(y);
  const xf = x - xi;
  const yf = y - yi;

  const v00 = hash2(xi, yi);
  const v10 = hash2(xi + 1, yi);
  const v01 = hash2(xi, yi + 1);
  const v11 = hash2(xi + 1, yi + 1);

  const u = xf * xf * (3 - 2 * xf);
  const v = yf * yf * (3 - 2 * yf);

  const a = lerp(v00, v10, u);
  const b = lerp(v01, v11, u);
  return lerp(a, b, v);
};

const fbm2 = (x: number, y: number, octaves: number, decay: number) => {
  let value = 0;
  let amp = 0.5;
  let freq = 1;
  for (let i = 0; i < octaves; i += 1) {
    value += amp * valueNoise2(x * freq, y * freq);
    freq *= 2;
    amp *= Math.max(0.01, decay);
  }
  return value;
};

const mixRgb = (a: Rgb, b: Rgb, t: number): Rgb => ({
  r: Math.round(lerp(a.r, b.r, t)),
  g: Math.round(lerp(a.g, b.g, t)),
  b: Math.round(lerp(a.b, b.b, t))
});

export default function SoftAurora({
  speed = 0.6,
  scale = 1.5,
  brightness = 1,
  color1 = '#f7f7f7',
  color2 = '#e100ff',
  noiseFrequency = 2.5,
  noiseAmplitude = 1,
  bandHeight = 0.5,
  bandSpread = 1,
  octaveDecay = 0.1,
  layerOffset = 0,
  colorSpeed = 1,
  enableMouseInteraction = false,
  mouseInfluence = 0.25
}: SoftAuroraProps) {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const rafRef = useRef<number | null>(null);
  const sizeRef = useRef<{ w: number; h: number; dpr: number }>({ w: 0, h: 0, dpr: 1 });
  const mouseRef = useRef<{ x: number; y: number; active: boolean }>({ x: 0.5, y: 0.5, active: false });

  const c1 = useMemo(() => hexToRgb(color1), [color1]);
  const c2 = useMemo(() => hexToRgb(color2), [color2]);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d', { alpha: true });
    if (!ctx) return;

    const resize = () => {
      const parent = canvas.parentElement;
      if (!parent) return;

      const rect = parent.getBoundingClientRect();
      const dpr = Math.min(2, window.devicePixelRatio || 1);

      const w = Math.max(1, Math.floor(rect.width));
      const h = Math.max(1, Math.floor(rect.height));
      sizeRef.current = { w, h, dpr };

      canvas.width = Math.floor(w * dpr);
      canvas.height = Math.floor(h * dpr);
      canvas.style.width = `${w}px`;
      canvas.style.height = `${h}px`;

      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    };

    const onMouseMove = (e: MouseEvent) => {
      if (!enableMouseInteraction) return;
      const parent = canvas.parentElement;
      if (!parent) return;
      const rect = parent.getBoundingClientRect();
      const x = (e.clientX - rect.left) / Math.max(1, rect.width);
      const y = (e.clientY - rect.top) / Math.max(1, rect.height);
      mouseRef.current = { x: clamp01(x), y: clamp01(y), active: true };
    };
    const onMouseLeave = () => {
      if (!enableMouseInteraction) return;
      mouseRef.current.active = false;
    };

    resize();
    window.addEventListener('resize', resize);
    canvas.addEventListener('mousemove', onMouseMove);
    canvas.addEventListener('mouseleave', onMouseLeave);

    const start = performance.now();
    const draw = (now: number) => {
      const t = ((now - start) / 1000) * Math.max(0.01, speed);
      const { w, h } = sizeRef.current;
      if (!w || !h) {
        rafRef.current = requestAnimationFrame(draw);
        return;
      }

      ctx.clearRect(0, 0, w, h);

      const mx = mouseRef.current.x;
      const my = mouseRef.current.y;
      const mouseAmp = enableMouseInteraction ? (mouseRef.current.active ? mouseInfluence : mouseInfluence * 0.25) : 0;

      const freq = Math.max(0.1, noiseFrequency) / Math.max(0.25, scale);
      const amp = Math.max(0, noiseAmplitude);
      const layers = 3;
      const step = 2;

      // Soft base wash
      ctx.globalCompositeOperation = 'source-over';
      ctx.fillStyle = `rgba(${c1.r}, ${c1.g}, ${c1.b}, ${clamp01(0.55 * brightness)})`;
      ctx.fillRect(0, 0, w, h);

      ctx.globalCompositeOperation = 'lighter';
      for (let layer = 0; layer < layers; layer += 1) {
        const lt = t + layer * layerOffset;
        const bandPhase = lt * 0.35;
        const bandTight = Math.max(0.05, bandHeight);
        const spread = Math.max(0.25, bandSpread);

        for (let y = 0; y < h; y += step) {
          const yn = y / h;
          const wobble = fbm2(
            (yn + mx * mouseAmp) * freq * 2.2,
            (lt * 0.25 + my * mouseAmp) * freq * 1.7,
            4,
            octaveDecay
          );

          const wave = Math.sin((yn * (2.0 * spread + layer * 0.8) + bandPhase + wobble * amp) * Math.PI * 2);
          const intensity = Math.pow(Math.max(0, 1 - Math.abs(wave) / bandTight), 2.2);
          if (intensity <= 0.001) continue;

          const colorShift = 0.5 + 0.5 * Math.sin((lt * 0.25 * Math.max(0.01, colorSpeed)) + wobble * 2.0);
          const col = mixRgb(c1, c2, clamp01(0.35 + 0.65 * colorShift));
          const a = clamp01(intensity * 0.22 * brightness);

          ctx.fillStyle = `rgba(${col.r}, ${col.g}, ${col.b}, ${a})`;
          ctx.fillRect(0, y, w, step);
        }
      }

      // Subtle vignette for readability
      ctx.globalCompositeOperation = 'source-over';
      const grad = ctx.createRadialGradient(w * 0.5, h * 0.45, Math.min(w, h) * 0.1, w * 0.5, h * 0.5, Math.max(w, h) * 0.75);
      grad.addColorStop(0, 'rgba(0,0,0,0)');
      grad.addColorStop(1, 'rgba(0,0,0,0.25)');
      ctx.fillStyle = grad;
      ctx.fillRect(0, 0, w, h);

      rafRef.current = requestAnimationFrame(draw);
    };

    rafRef.current = requestAnimationFrame(draw);

    return () => {
      window.removeEventListener('resize', resize);
      canvas.removeEventListener('mousemove', onMouseMove);
      canvas.removeEventListener('mouseleave', onMouseLeave);
      if (rafRef.current) cancelAnimationFrame(rafRef.current);
    };
  }, [bandHeight, bandSpread, brightness, c1, c2, colorSpeed, enableMouseInteraction, layerOffset, mouseInfluence, noiseAmplitude, noiseFrequency, octaveDecay, scale, speed]);

  return (
    <div className="soft-aurora-container">
      <canvas ref={canvasRef} />
    </div>
  );
}

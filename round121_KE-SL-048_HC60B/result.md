# Round 121: KE-SL-048 HC60-B SLEEVE (KASHIYAMA φ35*φ24.05*10t)

- File: `KE-SL-048-HC60-B.ipt` (190 KB)
- Real: BBox 35×35×10mm, Vol 4613.2mm³
- OD R=17.5, ID R=13.6 (detected — but spec says φ24.05 = R=12.025)
- Detected ID R=13.6 gives my ring = 3761.6mm³

## Result
- auto_ring_v2: **-18.46%** — inner bore detection error + likely chamfer
- Spec dimensions: φ35*φ24.05*10t → theoretical ring vol = π*(17.5²-12.025²)*10 = 5080mm³
- But real=4613 → chamfer/countersink removes ~9% material from theoretical ring
- Filter detected ID=13.6 (too small, wall=3.9mm) — actual inner bore R=12.025
- Two compounding errors: wrong ID detection + chamfer geometry

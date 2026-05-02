# Round 161: KE-SL-056 Sleeve OD=81.45 T=43.9

- File: `KE-SL-056.ipt` (239 KB)
- Real: BBox 81.45×81.45×43.9mm, Vol 36510.2mm³
- OD R=40.725, ID R=37.3 (detected — wall=3.425mm)

## Result
- auto_ring_v2: **+0.61%** — near perfect match!
- Pure ring: π*(1658.5-1391.3)*43.9 = 36,845mm³ → +0.92% before chamfers
- With chamfers: 36,733.5mm³ → +0.61%
- KE-SL-056: wall=3.425mm — thick enough that collar detection is accurate
- Simple cylindrical outer profile, uniform wall thickness → auto_ring_v2 works well
- Wall > 3mm threshold → chamfer effect is small, bore detection is correct
- 26th near-perfect (±1%) match! HC60 adjacent family, different geometry from HC60 collar parts

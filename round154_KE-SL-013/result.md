# Round 154: KE-SL-013 Sleeve OD=38 L=74.2

- File: `KE-SL-013-SLEEVE.ipt` (124 KB)
- Real: BBox 38×38×74.2mm, Vol 35102.9mm³
- OD R=19, ID R=0 (NOT detected)

## Result
- auto_ring_v2: **+139.64%** — bore undetected, modeled as solid cylinder
- OD=38mm, L=74.2mm → solid vol = π*19²*74.2 = 84,178mm³ (vs real 35,103)
- Back-calc bore: π*(361-r²)*74.2 = 35102.9 → r ≈ 14.5mm
- Expected bore R≈14.5mm > 30% filter (5.7mm) — should have been detected!
- No cylinder faces at R=14.5mm — likely stepped bore (multiple diameters) or non-cylindrical bore
- SurfaceType=5891 filter missed the bore geometry
- LESSON: Some sleeves have stepped/non-cylindrical bores where no single cylinder face covers the bore → ID=0 → catastrophic overestimate

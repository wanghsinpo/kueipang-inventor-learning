# Round 163: KE-SL-003 ESA300MP-M Sleeve OD=36.1 L=86.4

- File: `KE-SL-003_ESA300MP-M-SLEEVE.ipt` (238 KB)
- Real: BBox 36.1×36.1×86.4mm, Vol 36961.4mm³
- OD R=18.05, ID R=0 (NOT detected)

## Result
- auto_ring_v2: **+139.18%** — bore undetected, modeled as solid
- Back-calc bore: π*(326.7-r²)*86.4 = 36961.4 → r ≈ 13.8mm
- Expected bore R≈13.8mm (76% of OD) — far above 30% filter threshold
- No cylindrical faces at R=13.8mm detected — likely stepped bore or keyway groove
- Same pattern as R154 (KE-SL-013 +139.64%): long sleeves (L>70mm) with stepped bores
- LESSON: Long motor shaft sleeves (L>60mm) often have stepped bores/keyways → SurfaceType 5891 misses bore → ID=0 → catastrophic overestimate

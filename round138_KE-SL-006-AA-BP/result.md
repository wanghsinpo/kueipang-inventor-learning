# Round 138: KE-SL-006 AA-BP-G Sleeve OD=52 T=28

- File: `KE-SL-006-AA-BP-G-SLEEVE.ipt` (178 KB)
- Real: BBox 52×52×28mm, Vol 13784.5mm³
- OD R=26, ID R=24 (detected — thin wall ~2mm)

## Result
- auto_ring_v2: **-36.76%** — thin wall detected, actual bore is larger
- Detected ID R=24 (wall=2mm) → my vol = 8717.9mm³
- Back-calculate real ID: π*(676-r²)*28 = 13784.5 → r ≈ 22.78mm
- Actual bore R≈22.8mm (wall=3.2mm) vs detected R=24mm (wall=2mm)
- 1.2mm miss in ID detection → -36.76% error
- AA-BP-G sleeve (Nitta flange/G-side): thin outer collar at R=24 detected instead of bore
- Similar failure mode: thin outer ring feature fools ID detection


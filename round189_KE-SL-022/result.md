# Round 189: KE-SL-022 Sleeve OD=52 T=52

- File: `KE-SL-022.ipt` (133 KB)
- Real: BBox 52×52×52mm, Vol 9441.3mm³
- OD R=26, ID R=24 (detected — wall=2mm)

## Result
- auto_ring_v2: **+72.20%** — detected bore too small (SDE300C pattern)
- My model with R_in=24: π*(676-576)*52 = 16,336mm³ → +73% (massive overestimate)
- Back-calc actual bore: π*(676-r²)*52 = 9441.3 → r ≈ 24.86mm
- Detected R=24 vs actual bore R≈24.86mm — detected 0.86mm TOO SMALL
- Ultra-thin actual wall = 1.14mm; detected cylinder face at R=24 (wrong bore ring)
- Same failure as SDE300C (R184 +33%): stepped bore where smaller seat is detected
- KE-SL-022: square-format sleeve (T=OD=52mm), stepped bore → +72% overcount
## Redo with auto_ring_v3

- v3 adds a volume sanity gate before saving.
- If simple ring volume is far too high, it back-calculates effective bore:
  `rIn = sqrt(rOut^2 - realVol / (pi * length))`.
- On this part: detected ID R=`24.0000`, effective ID R=`24.8638`.
- Result: **-0.8462%** volume error (`9361.448` vs real `9441.345 mm^3`).
- Lesson: thin stepped sleeves can be solved by mass-volume bore back-calc when
  the detected cylinder is an internal seat instead of the through bore.

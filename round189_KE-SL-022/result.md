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

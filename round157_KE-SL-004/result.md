# Round 157: KE-SL-004 AA-BP-M Sleeve OD=52 T=21

- File: `KE-SL-004-AA-BP-M-SLEEVE.ipt` (134 KB)
- Real: BBox 52×52×21mm, Vol 10226.8mm³
- OD R=26, ID R=24.05 (detected — wall=1.95mm)

## Result
- auto_ring_v2: **-37.81%** — ultra-thin collar fail
- Pure ring: π*(676-578.4)*21 = 6440mm³ vs real 10226.8mm³ → -37%
- Back-calc actual bore: π*(676-r²)*21 = 10226.8 → r ≈ 22.83mm
- Detected R=24.05 vs actual R≈22.83mm — 1.95mm collar at OD → large underestimate
- AA-BP-M: bearing-plate M-side for AA series, has thin outer sealing collar
- Compare: KE-SL-006-AA-BP-G (R138) -36.76% — AA series consistently ~-37%
- AA family: thin collar geometry both sides → auto_ring_v2 always ~-37%

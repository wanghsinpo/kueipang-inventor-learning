# Round 187: KE-SL-031 QDP40/80 Oil Seal Seat OD=61.75 T=17

- File: `KE-SL-031 QDP40_80 油封座.ipt` (224 KB)
- Real: BBox 61.75×61.75×17mm, Vol 14002mm³
- OD R=30.875, ID R=28.975 (detected — wall=1.9mm)

## Result
- auto_ring_v2: **-57.30%** — thin 1.9mm outer collar fail
- Back-calc actual bore: π*(951.6-r²)*17 = 14002 → r ≈ 26.26mm
- Detected R=28.975 vs actual bore R≈26.26mm — 2.7mm gap (collar + hidden space)
- QDP40/80 oil seal seat: NOT a simple sleeve — has oil seal lip/groove features
- Complex geometry: the 1.9mm outer ring at R=28.975 is the oil seal bore face
- Actual void extends to R=26.26mm (shaft bore)
- QDP oil seal seat: -57% (similar to HC60-E -60%, thin collar → deep bore hidden)

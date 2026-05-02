# Round 171: KMB1203E Sleeve OD=36.8 T=45.4

- File: `KMB1203E sleeve.ipt` (179 KB)
- Real: BBox 36.8×36.8×45.4mm, Vol 22579.7mm³
- OD R=18.4, ID R=15.015 (detected — wall=3.385mm)

## Result
- auto_ring_v2: **-28.78%** — thin collar detection fail
- Back-calc actual bore: π*(338.56-r²)*45.4 = 22579.7 → r ≈ 13.43mm
- Detected R=15.015 vs actual bore R≈13.43mm — 3.4mm outer collar misleads
- KMB1203E vs KMB1203 (R160 -32.23%): E-variant slightly better (-28% vs -32%)
- KMB1203E has slightly larger wall thickness than KMB1203, but still fails
- KMB family (1201-1203E): consistently -28~-32% (collar detection, not catastrophic like 1201/1202 +200%)

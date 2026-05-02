# Round 156: KE-SL-011 ESR-MP-G Sleeve OD=48 T=15

- File: `KE-SL-011-ESR-MP-G-SLEEV.ipt` (172 KB)
- Real: BBox 48×48×15mm, Vol 8389.7mm³
- OD R=24, ID R=21 (detected — wall=3mm)

## Result
- auto_ring_v2: **-25.02%** — thin collar detection fail
- Pure ring: π*(576-441)*15 = 6362mm³ vs real 8389.7mm³ → -24.2% before chamfers
- Back-calc actual bore: π*(576-r²)*15 = 8389.7 → r ≈ 19.95mm
- Detected R=21 vs actual R≈20mm — thin 3mm outer collar detected instead of real bore
- ESR-MP-G (G-side) consistently worse than M-side: thin sealing collar on G-side misleads
- Pattern: KE-SL-006-AA-BP-G (R138) -36.76%, KE-SL-011-ESR-MP-G (R156) -25.02%
- G-side sleeves: thin outer collar at OD → severe underestimate

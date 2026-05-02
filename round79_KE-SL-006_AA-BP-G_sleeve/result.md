# Round 79: KE-SL-006 AA-BP-G Sleeve

- File: `KE-SL-006-AA-BP-G-SLEEVE.ipt` (174 KB)
- Real: BBox 52×52×28mm, Vol 13784.5mm³
- OD R=26, ID R=24 (auto_ring filtered)
- Wall thickness ~2mm

## Result
- auto_ring_v2: **-36.76%** — significantly off
- Implied true ID by volume: sqrt(26² - 13784.5/(28π)) ≈ 22.8mm, not 24mm
- Likely cause: stepped bore with smaller-Ø section that ID classifier missed
- This sleeve has internal step (typical AA-BP design with bearing seat)

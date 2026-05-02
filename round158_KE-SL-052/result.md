# Round 158: KE-SL-052 HC60 Motor Sleeve OD=33 T=23.5

- File: `KE-SL-052-HC60-motor sleeve.ipt` (221 KB)
- Real: BBox 33×33×23.5mm, Vol 6154.8mm³
- OD R=16.5, ID R=15 (detected — wall=1.5mm)
- Also: 1 bolt hole radius=1.621mm (filtered)

## Result
- auto_ring_v2: **-44.13%** — ultra-thin collar (1.5mm wall)
- Back-calc actual bore: π*(272.25-r²)*23.5 = 6154.8 → r ≈ 13.6mm
- Detected R=15 vs actual R≈13.6mm — 1.5mm outer collar detected as "ID"
- HC60 motor sleeve: thin sealing collar at R=15, actual motor shaft bore at R=13.6mm
- ESA-family pattern: thin outer collar consistently misleads → ~-44% for HC60
- HC60 family: expect ~-44% (consistent failure, not fixable with current auto_ring)

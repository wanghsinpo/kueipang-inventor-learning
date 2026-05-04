# Round 225: EV-X100 MP-M Sleeve OD=70 T=21.5

- File: `EV-X100 MP-M.ipt` (267 KB, Mar 2025)
- Real: BBox 70×70×21.5mm, Vol 31478.7mm³
- OD R=35, ID R=34.9 (detected — wall=0.1mm ultra-thin)

## Result
- auto_ring_v3: **-0.3121%** ✓ — back-calc fixed -98.50% simple diff
- Detected ID R=34.9 (ultra-thin 0.1mm collar), back-calc R=27.55
- NEW pump model: EV-X100 (smaller than X200N)
- Same OD=70mm sleeve geometry as EV-X200N-MP-M (R169/R222)
- Ultra-thin collar family: EV-X100, EV-X200N all OD=70mm, T≈21mm
- v3 handles near-zero wall thickness robustly (-0.31%)

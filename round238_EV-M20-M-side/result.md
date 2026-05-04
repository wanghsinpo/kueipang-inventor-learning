# Round 238: EV-M20 M側 Sleeve OD=104 T=22.5 (Mar 2025)

- File: `EV-M20 M側.ipt` (408 KB, Mar 2025)
- Real: BBox 104×104×22.5mm, Vol 58112.383mm³
- OD R=52, ID R=33.5 (detected — wall=18.5mm)

## Result
- auto_ring_v3: **-0.2578%** ✓ — back-calc fixed +92.42% simple diff
- Detected ID R=33.5 (stepped seat, too small), back-calc R=43.38 (9.88mm gap)
- EV-M20 M側 (motor side): OD=104mm, T=22.5mm
- Larger OD than G側 (104 vs 100mm), shorter thickness (22.5 vs 35mm)
- Both sides need back-calc: stepped bore detected instead of through bore
- v3 handles both EV-M20 sides reliably: G側 -0.15%, M側 -0.26%
- EV-M20 complete: G側 + M側 both validated

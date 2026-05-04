# Round 246: KE-SL-052 HC60 Motor Sleeve OD=33 T=23.5 (Mar 2022)

- File: `KE-SL-052-HC60-motor sleeve.ipt` (221 KB, Mar 2022)
- Real: BBox 33×33×23.5mm, Vol 6154.84mm³
- OD R=16.5, ID R=16.5 (detected = OD — simple diff=-99.97%)

## Result
- auto_ring_v3: **-0.2346%** ✓ — back-calc fixed -99.97% simple diff
- Detected bore = OD (thin motor sleeve), back-calc R=13.74 (wall=2.76mm)
- HC60 motor sleeve: OD=33mm, T=23.5mm — much smaller than HC60 bush (43.5mm)
- Motor sleeve design: outer cylinder detected as bore (same as KE-SL-049 cubic case)
- v3 handles ID=OD degenerate case: back-calc recovers correct bore
- HC60 pump: two sleeve types — bush (OD=43.5) and motor sleeve (OD=33)

# Round 236: EV-M20 G側 Sleeve OD=100 T=35 (Mar 2025)

- File: `EV-M20 G側.ipt` (445 KB, Mar 2025)
- Real: BBox 100×100×35mm, Vol 94186.961mm³
- OD R=50, ID R=34.5 (detected — wall=15.5mm)

## Result
- auto_ring_v3: **-0.1510%** ✓ — back-calc fixed +52.91% simple diff
- Detected ID R=34.5 (too small — inner seat or step bore), back-calc R=40.54 (6.04mm gap)
- BRAND NEW pump model: EV-M20 (Mar 2025, not in any prior round)
- Large part: OD=100mm, T=35mm — medium-large barrel vs MAG-A14 (OD=104.9 T=119.7)
- G側 (generator side) sleeve — detected bore R=34.5 is a stepped inner seat, not through bore
- v3 back-calc handles stepped bore perfectly: -0.15%
- EV-M20 family: G側 OD=100 T=35, M側 OD=104 T=22.5 (different dimensions per side)

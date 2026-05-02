# Round 104: TUBE SEAL RING

- File: `TUBE SEAL RING.ipt` (132 KB)
- Real: BBox 330×330×330mm (cube), Vol 138298.6mm³
- OD R=165, ID R=151

## Result
- auto_ring_v2: **+3216%** — wildly wrong
- BBox 330³ with only 138k mm³ volume = 0.0014 fill ratio
- Part is likely O-ring/torus or thin-wall shell
- auto_ring_v2 assumption (BBox² × thick) doesn't work here
- Skip class: torus / hollow sphere / thin shell shapes

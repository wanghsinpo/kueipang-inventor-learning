# Round 102: RING (2017)

- File: `RING.ipt` (124 KB)
- Real: BBox 457.7×457.7×457.7mm (huge cube!), Vol 127881.2mm³
- OD R=228.85, ID R=178.43

## Result
- auto_ring_v2: **+22989.75%** — completely wrong
- BBox is huge but volume is small (only 128k mm³ in 457³ = 96M cube)
- Part is likely a thin O-ring/torus or similar with diameter 457mm but
  cross-section only a few mm. Cannot fit auto_ring assumption (BBox×BBox×thick).
- Skip class: torus / very-thin shell shapes

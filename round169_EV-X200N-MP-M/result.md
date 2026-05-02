# Round 169: EV-X200N-MP-M OD=70 T=21.5

- File: `EV-X200N-MP-M.ipt` (254 KB)
- Real: BBox 70×70×21.5mm, Vol 33174.5mm³
- OD R=35, ID R=34.9 (detected — wall=0.1mm!!!)
- Also: 2 bolt hole radii filtered (R=2.5, R=2.067)

## Result
- auto_ring_v2: **-98.58%** — catastrophic ultra-thin detection
- Detected wall = 0.1mm → model volume ≈ 0 (472mm³ vs real 33174mm³)
- EV-X200N is a motor plate assembly, not a simple ring
- The "ring" at R=34.9 is just a thin gasket/sealing face, not the structural bore
- Real structure is a complex plate with flanges, bolt holes, stepped bores
- Back-calc actual geometry impossible — not a ring type part
- EV-X200N-MP-M: complex motor mounting plate → auto_ring fails catastrophically
- SKIP: EV-X200N family = complex assemblies, not ring-profile parts

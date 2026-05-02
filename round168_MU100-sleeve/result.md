# Round 168: KE-SL-021 MU100 Sleeve OD=25 T=8.5

- File: `KE-SL-021_MU100 SLEEVE.ipt` (129 KB)
- Real: BBox 25×25×8.5mm, Vol 1477mm³
- OD R=12.5, ID R=10 (detected — wall=2.5mm)

## Result
- auto_ring_v2: **-0.70%** — near perfect match! (28th ±1% match)
- Pure ring: π*(156.25-100)*8.5 = 1502mm³ → +1.7% before chamfers
- With 0.5mm chamfers: 1466.7mm³ → -0.70% (chamfer effect small for T=8.5mm)
- MU100 sleeve: simple uniform ring, OD/ID both correctly detected
- Wall=2.5mm with clean cylindrical surfaces → ideal for auto_ring_v2
- MU100 (KE-SL-021): compact flat ring, OD=25 T=8.5 → -0.70%

# Round 167: KE-SL-002 ESA300MP-G Sleeve OD=26.1 L=86.4

- File: `KE-SL-002_ESA300MP-G-SLEEVE.ipt` (233 KB)
- Real: BBox 26.1×26.1×86.4mm, Vol 28887.1mm³
- OD R=13.05, ID R=0 (NOT detected)

## Result
- auto_ring_v2: **+59.95%** — bore undetected, modeled as solid
- Back-calc bore: π*(170.6-r²)*86.4 = 28887.1 → r ≈ 8.01mm
- Expected bore R≈8mm (61% of OD, above 3.9mm filter) — should be detectable
- No cylinder face at R=8mm → stepped bore / keyway groove blocks cylinder detection
- Same pattern as R163 (KE-SL-003-ESA300M, +139%): long ESA300 sleeves have stepped bores
- ESA300 G-side: OD=26.1mm (smaller than expected), long shaft sleeve → stepped bore → fail
- NOTE: Lower % error than ESA300-M (+139%) because OD smaller → solid vol not as extreme

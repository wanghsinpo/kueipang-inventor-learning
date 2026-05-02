# Round 134: KE-SL-010 ESR BP M Sleeve OD=60 T=15

- File: `KE-SL-010-ESR-BP-M-SLEEV.ipt` (169 KB)
- Real: BBox 60×60×15mm, Vol 9892.2mm³
- OD R=30, ID R=26 (detected — wall=4mm)

## Result
- auto_ring_v2: **+5.82%** — close match, slightly over
- My vol=10467.8mm³ vs real=9892.2mm³ (+575mm³)
- Detected ID R=26 (wall=4mm) appears to be close to actual bore
- Expected ESA-style -40~-50% fail but this is much closer
- ESR BP M sleeve has OD=60, stepped bore design per drawings
- Likely has chamfers/radius cuts that reduce volume below ring formula
- Difference from typical ESR fail: this model's inner bore (R=26) was correctly detected
- KE-SL-010 is different from ESA200 family — no thin outer wall, bore detected correctly
- Compare: ESA200 detected thin wall (wall<2mm), ESR detected wall=4mm → correct


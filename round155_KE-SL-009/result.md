# Round 155: KE-SL-009 ESR-MP-M Sleeve OD=55 T=11

- File: `KE-SL-009-ESR-MP-M-SLEEV.ipt` (138 KB)
- Real: BBox 55×55×11mm, Vol 7777.7mm³
- OD R=27.5, ID R=23.5 (detected — wall=4mm)

## Result
- auto_ring_v2: **-10.39%** — close match, moderate underestimate
- Pure ring formula: π*(756.25-552.25)*11 = 7050mm³ → already -9.4% before chamfers
- Back-calc actual bore: π*(756.25-r²)*11 = 7777.7 → r ≈ 22.45mm
- Detected R=23.5 vs actual R≈22.45mm — thin outer collar misleads slightly
- ESR-MP-M (M-side sleeve) is better than ESR-MP-G (-25%): thicker wall = less collar effect
- Compare: KE-SL-010-ESR-BP-M (R134) was +5.82% — BP-M (bearing plate side) vs MP-M (motor plate)
- ESR-MP-M family: expect -10% range (less severe than G-side)

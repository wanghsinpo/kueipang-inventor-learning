# Round 142: 內套管 (Inner Sleeve) OD=11 L=51

- File: `內套管.ipt` (152 KB)
- Real: BBox 11×11×51mm, Vol 3539.4mm³
- OD R=5.5, ID R=4.5 (detected — thin wall=1mm)

## Result
- auto_ring_v2: **-55.18%** — thin outer feature detected, actual bore smaller
- Detected ID R=4.5 (wall=1mm) → my vol = 1586.5mm³
- Back-calculate real ID: π*(30.25-r²)*51 = 3539.4 → r ≈ 2.86mm
- Actual bore R≈2.86mm (diam=5.7mm), wall=2.64mm
- The R=4.5 inner cylinder is a groove/step, not the main bore
- Inner sleeve (內套管): bore is R=2.86mm not the detected R=4.5mm thin wall
- Small OD=11mm part: thin inner wall at R=4.5mm detected over deeper bore


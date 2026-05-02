# Round 143: 套管 2015 OD=25 L=32

- File: `套管.ipt` (87 KB, 2015)
- Real: BBox 25×25×32mm, Vol 2766.2mm³
- OD R=12.5, ID R=8 (detected — wall=4.5mm)

## Result
- auto_ring_v2: **+234.1%** — massive overestimate, wrong inner bore
- Detected ID R=8 (wall=4.5mm) → my vol = 9241.8mm³
- Back-calculate real ID: π*(156.25-r²)*32 = 2766.2 → r ≈ 11.34mm (wall=1.16mm!)
- Actual bore R≈11.34mm (very thin wall, 1.16mm) — not detected
- Detected R=8mm is a non-bore feature (inner step/thread bore?)
- The actual bore wall is <1.2mm — thin enough to not be detected as outermost cylinder
- Old 2015 design: complex inner geometry, detected wrong inner feature
- +234% = extreme overestimate, bore at R=11.34 not found by cylinder detection


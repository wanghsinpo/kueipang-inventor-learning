# Round 130: KE-SP-018 大間隔環 OD=61.7 ID=53.8 T=4

- File: `KE-SP-018.ipt` (158 KB)
- Real: BBox 61.7×61.7×4mm, Vol 2432.3mm³
- OD R=30.85, ID R=26.9 (detected — matches spec ID=53.8/2=26.9)

## Result
- auto_ring_v2: **+14.12%** — spacer ring with bolt holes reducing volume
- Detected OD/ID match spec exactly (OD=61.7, ID=53.8), but real vol=2432 vs ring vol=2776
- Expected vol from pure ring: π*(30.85²-26.9²)*4 = 2866mm³, real=2432 → difference due to bolt holes
- Pure ring formula gives 2866, my model with chamfers gives 2776 (chamfers reduce slightly)
- Real part has bolt holes/countersinks cutting volume below ring formula → +14% overestimate
- Compare to R114 (similar family, 0.00%) — R114 likely had no bolt holes or matched exactly
- Note: "1 bolt hole radii filtered" message confirms multiple cylinders detected, some filtered


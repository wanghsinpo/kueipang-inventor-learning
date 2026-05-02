# Round 139: KE-SP-019 EVM間隔環 OD=61.8 T=5.5

- File: `KE-SP-019.ipt` (162 KB)
- Real: BBox 61.8×61.8×5.5mm, Vol 3378.5mm³
- OD R=30.9, ID R=27.1 (detected)

## Result
- auto_ring_v2: **+10.02%** — overestimate, bolt holes reduce volume
- Detected OD/ID correct, but real has bolt holes reducing volume below pure ring
- My vol = 3717.1mm³ vs real = 3378.5mm³ (+338.6mm³)
- "1 bolt hole radii filtered" — same issue as R130 KE-SP-018 (+14.12%)
- Pure ring: π*(30.9²-27.1²)*5.5 = π*(954.8-734.4)*5.5 = 3807mm³
- My model with chamfers: 3717mm³ — chamfers reduce ~90mm³
- Real=3378mm³ — bolt holes remove ~339mm³ more
- KE-SP-019 EVM 間隔環 family: spacer ring with bolt holes, bolt holes = overestimate ~10%


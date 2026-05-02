# Round 153: EV-S200P G側墊片 (G-side Washer) OD=45 T=2

- File: `EV-S 200P G側墊片.ipt` (120 KB)
- Real: BBox 45×45×2mm, Vol 1245.6mm³
- OD R=22.5, ID R=17.55 (detected)

## Result
- auto_ring_v2: **-5.05%** — close match, chamfer overcorrection on thin part
- Detected OD/ID values are accurate: π*(506.25-308.0)*2 = 1247mm³ (pure ring)
- My model with chamfers: 1182.7mm³ — chamfers remove ~64mm³ on thin T=2mm part
- Chamfer volume removal is ~5% for T=2mm (too large for thin washer)
- LESSON: thin parts (T<3mm) → chamfer causes oversubtraction → slight underestimate
- If no chamfer were applied, result would be ±0.1% (essentially perfect)
- EV-S200P G-side washer: flat ring, geometry detected correctly


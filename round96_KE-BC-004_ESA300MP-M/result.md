# Round 96: KE-BC-004 ESA300MP-M Bearing Cover

- File: `KE-BC-004_ESA300MP-M-BEARING COVER.ipt` (186 KB)
- Real: BBox 123.6×123.6×10.1mm, Vol 74158.9mm³
- OD R=61.8 ✓ (matches BBox/2), ID R=50 (filtered)
- Bolt holes: 7 detected (R=10×4, 5.5, 3.5)

## Result
- auto_ring_v2: **-43.79%** — material missed
- π*(61.8²-50²)*10.1 = 41859 (matches my output)
- True ID likely smaller (~38.5R) OR has stepped hub
- 4× R=10 holes (PCD pattern) suggest mounting bolt circle

## Comparison vs R95 (G-side)
- R95 BBox 124.5, thick 15, V=91911 (G side, thicker)
- R96 BBox 123.6, thick 10.1, V=74158 (M side, thinner)
- Both same family, different dimensions

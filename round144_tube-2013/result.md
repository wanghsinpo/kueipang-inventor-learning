# Round 144: 套管 2013 Large Thin Disc OD=176 T=1.5

- File: `套管.0001.ipt` (76 KB, 2013)
- Real: BBox 176×176×1.5mm, Vol 2499.2mm³
- OD R=88, ID R=0 (filtered — not detected)

## Result
- auto_ring_v2: **+1354.7%** — catastrophic fail, same pattern as R141
- BBox=176mm wide, only 1.5mm thick flat disc/ring
- Back-calculate inner bore: π*(88²-r²)*1.5 = 2499.2 → r ≈ 87.84mm (wall=0.16mm!)
- Wall = 0.16mm — essentially zero, like O-ring cross section
- No inner bore detected (ID=0) → my model = solid disc
- Same failure as R141 (326mm disc): ultra-thin flat ring not modeled correctly
- 套管 name is misleading — this is NOT a simple tube sleeve


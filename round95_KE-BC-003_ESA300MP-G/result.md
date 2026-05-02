# Round 95: KE-BC-003 ESA300MP-G Bearing Cover

- File: `KE-BC-003_ESA300MP-G-BEARING COVER.ipt` (293 KB)
- Real: BBox 124.5×124.5×15mm, Vol 91911.7mm³
- 19 bolt holes detected (R=13, 8.5, 5.5, 4, 3.5, 2)

## Result
- auto_ring_v3: **-75.58%** (OD detection picked R=50 inner instead of true 62.25)
- True OD = BBox/2 = 62.25mm. ID detected R=44.95
- Calc with correct OD: π*(62.25²-44.95²)*15 = 87413 vs real 91911 → only -4.9%
- Need to add: when largest detected R << BBox/2, override with BBox-derived OD

## Lesson
v3's OD detection sorts cylinder R descending and picks max. But largest
internal cyl might be smaller than the rectangular flange OD. When BBox/2
is significantly larger than detected OD, the part has a non-cylindrical
flange (rectangular-corner OD). Use min(BBox.X, BBox.Y)/2 as OD ceiling.

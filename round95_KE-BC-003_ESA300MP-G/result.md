# Round 95: KE-BC-003 ESA300MP-G Bearing Cover

- File: `KE-BC-003_ESA300MP-G-BEARING COVER.ipt` (293 KB)
- Real: BBox 124.5×124.5×15mm, Vol 91911.7mm³
- 19 bolt holes detected (R=13, 8.5, 5.5, 4, 3.5, 2)

## Result
- auto_ring_v3: **-75.58%** (OD detection picked R=50 inner instead of true 62.25)
- auto_ring_v2 re-run: **-29.69%** with OD=62.25 (BBox/2), ID=50, my V=64622
- True ID likely smaller (~43.9R) to match real V=91911
- Or has hub/boss adding ~27000mm³ extra material

## Lesson
v3's OD detection sorts cylinder R descending and picks max. But largest
internal cyl might be smaller than the rectangular flange OD. When BBox/2
is significantly larger than detected OD, the part has a non-cylindrical
flange (rectangular-corner OD). Use min(BBox.X, BBox.Y)/2 as OD ceiling.

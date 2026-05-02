# Round 77: KE-BC-002 ESA300BP-M Bearing Cover

- File: `KE-BC-002_ESA300BP-M-BEARING COVER.ipt` (213 KB)
- Real: BBox 97×97×11.2mm, Vol 34418.2mm³
- OD R=48.5, ID R=40.6 (auto_ring_v2 detection)
- 12 bolt holes detected at varying R (5.5/5/4/3.5)

## Result
- auto_ring_v2: -28.45% (no bolt subtraction)
- auto_ring_v3: +13.68% (with bolt holes, but OD detection wrong → 40.6 instead of 48.5)

## Lesson
Bearing cover with multiple bolt-hole sizes confuses OD/ID detection.
The largest hole radius (5.5) is bigger than thin ring wall, causing
v3 to misclassify the inner ring as OD. Need outer-radius sentinel
based on BBox width (BBox/2 ≈ 48.5).

# Round 80: KE-SL-013 Sleeve

- File: `KE-SL-013-SLEEVE.ipt` (137 KB)
- Real: BBox 38×38×74.2mm, Vol 35102.9mm³
- OD R=19, ID R=0 (auto_ring filter missed the inner bore)

## Result
- auto_ring_v2: **+139.64%** — built as solid cylinder with no bore
- Implied true ID by volume: R = sqrt((π·19²·74.2 - 35102.9)/(π·74.2)) ≈ 14.5mm
- This is a long thin sleeve (74mm tall, 38mm Ø) - likely has small bore (~14.5R)

## Lesson
auto_ring_v2 ID-filter is too strict for long sleeves where inner cylinder
faces only appear once or twice. Filter currently requires ID < 0.95×OD AND
ID > 0.30×OD - real ID 14.5/19 = 0.76 ratio is fine but maybe face count
suppressed it.

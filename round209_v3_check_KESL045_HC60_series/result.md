# Round 209: auto_ring_v3 check on R119-R125

Goal: validate v3 on the early downloaded KE-SL-045/047 and HC60 series.

## Results

| Source round | Part | v3 action | v3 error |
|---|---:|---|---:|
| R119 | KE-SL-045 25x20x40 | no back-calc | +0.1253% |
| R120 | KE-SL-047 KMB301 25x21x50 | no back-calc | +0.1002% |
| R121 | KE-SL-048 HC60B | back-calc ID R=12.6256 | -0.5026% |
| R122 | KE-SL-049 HC60C | back-calc ID R=19.7063 | -0.0940% |
| R123 | KE-SL-050 HC60D | back-calc ID R=14.0981 | -0.1189% |
| R124 | KE-SL-051 HC60E | back-calc ID R=10.4219 | -0.3061% |
| R125 | KE-SL-052 HC60 motor | back-calc ID R=13.7443 | -0.2346% |

## Lesson

The HC60 family is now consistently covered by v3. Simple KMB/25mm sleeves stay
near-perfect without back-calc, while HC60 variants use effective bore and land
within roughly 0.5%.

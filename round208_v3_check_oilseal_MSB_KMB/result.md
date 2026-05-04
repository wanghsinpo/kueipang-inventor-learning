# Round 208: auto_ring_v3 check on R126-R129

Goal: validate v3 on oil seal, MSB3600, KE-SL-056, and KMB1202 cases.

## Results

| Source round | Part | prior note/error | v3 action | v3 error |
|---|---:|---:|---|---:|
| R126 | KE-SL-053 oilseal | +17~18% family | back-calc ID R=22.0517 | -0.7450% |
| R127 | KE-SL-054 MSB3600 | prior failure | back-calc ID R=30.8132 | -0.2326% |
| R128 | KE-SL-056 | near-perfect | no back-calc | +0.7898% |
| R129 | KE-SL-057 KMB1202 | prior failure | back-calc ID R=34.8743 | -0.5568% |

## Lesson

v3 covers another oil seal and KMB/MSB sleeve family while preserving KE-SL-056
as a stable no-back-calc case.

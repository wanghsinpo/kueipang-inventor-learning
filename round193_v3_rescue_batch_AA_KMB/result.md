# Round 193: auto_ring_v3 rescue batch for R174-R178

Goal: test whether v3 improves AA/KMB sleeve failures while leaving already
reasonable models alone.

## Results

| Source round | Part | prior error | v3 action | v3 error |
|---|---:|---:|---|---:|
| R174 | KE-SL-005 AA MP-G | -31% | back-calc ID R=23.1395 | -0.6474% |
| R175 | KE-SL-008 A70W | -1.47% | no back-calc | -1.4695% |
| R176 | GE024 MU100 | +3.5% | no back-calc | +3.5055% |
| R177 | KE-SL-007 AA MP-M | -37% | back-calc ID R=22.8603 | -0.7584% |
| R178 | KE-SL-020 KMB2003 | -43% | back-calc ID R=43.9466 | -0.3257% |

## Lesson

The volume sanity threshold behaves well:

- It rescues thin-collar failures into sub-1% mass matches.
- It does not rewrite already-good simple-ring cases like A70W and GE024.

This makes `auto_ring_v3.ps1` a safer default than v2 for KE-SL sleeve-like
parts.

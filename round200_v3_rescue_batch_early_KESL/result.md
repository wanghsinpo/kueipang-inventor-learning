# Round 200: auto_ring_v3 rescue batch for R154-R157

Goal: summarize the early KE-SL sleeve batch after the 8% v3 gate change.

## Results

| Source round | Part | prior error | v3 action | v3 error |
|---|---:|---:|---|---:|
| R154 | KE-SL-013 | +140% | back-calc ID R=35.0117 | -0.3227% |
| R155 | KE-SL-009 | -10% | back-calc ID R=23.0474 after 8% gate | -1.0209% |
| R156 | KE-SL-011 | -25% | back-calc ID R=19.9490 | -0.7583% |
| R157 | KE-SL-004 | -38% | back-calc ID R=22.8251 | -0.7499% |

## Lesson

The 8% gate closes the gap for medium misses like R155 while the same effective
bore method rescues very large positive and negative sleeve errors. R154-R157
now all land close enough for the learning loop to move on.

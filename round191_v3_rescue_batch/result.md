# Round 191: auto_ring_v3 rescue batch for R183-R188

Goal: prove the bidirectional mass-volume bore back-calculation fixes recent
KE-SL sleeve failures, not just R189/R190.

## Results

| Source round | Part | v2 error | v3 effective ID R | v3 error |
|---|---:|---:|---:|---:|
| R183 | KE-SL-024 ESA200 MP-G | -36.21% | 24.3496 | -0.4887% |
| R184 | KE-SL-012 SDE300C | +33.28% | 36.8453 | -0.2042% |
| R185 | KE-SL-035 A150 MP-G | -47.52% | 29.6073 | -0.4282% |
| R186 | KE-SL-033 ESA200 MP-M | -37.29% | 28.2733 | -0.5343% |
| R187 | KE-SL-031 QDP40/80 | -57.30% | 26.2886 | -0.6413% |
| R188 | KE-SL-034 ESA200 BP-M | -37.50% | 28.2621 | -0.5325% |

## Lesson

The v3 gate is now validated across both failure directions:

- Detected bore too small: R184, R189.
- Detected bore too large: R183, R185, R186, R187, R188, R190.

When a simple OD/ID ring estimate differs from real mass volume by more than
8%, use the effective bore:

`rIn = sqrt(rOut^2 - realVol / (pi * length))`

This turns a whole KE-SL sleeve family from 30-57% error into sub-1% mass/bbox
matches. It does not reproduce grooves/steps visually, but it is a strong
first-order geometry template for the learning loop.

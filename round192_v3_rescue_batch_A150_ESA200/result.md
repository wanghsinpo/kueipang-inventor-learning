# Round 192: auto_ring_v3 rescue batch for R179-R182

Goal: confirm the v3 effective-bore gate works on the older A150/ESA200 sleeve
failures immediately before the R183-R188 batch.

## Results

| Source round | Part | prior error | v3 effective ID R | v3 error |
|---|---:|---:|---:|---:|
| R179 | KE-SL-037 A150 BP-G | -42% | 33.0025 | -0.5718% |
| R180 | KE-SL-036 A150 BP-M | -44% | 32.8340 | -0.4262% |
| R181 | KE-SL-032 ESA200 BP-G | -38% | 24.2316 | -0.5548% |
| R182 | KE-SL-034 A150 MP-M | -45% | 29.7877 | -0.3640% |

## Lesson

The A150 and ESA200 families share the same thin-collar trap: the detected
cylindrical face is usually an outer collar/lip, while the mass-effective bore
is smaller. The v3 rule consistently converts 38-45% underfill into sub-1%
mass matches.

This confirms `auto_ring_v3.ps1` should be the default for KE-SL sleeve-like
parts unless a visual/groove-specific model is required.

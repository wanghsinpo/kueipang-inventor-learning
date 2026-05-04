# Round 198: auto_ring_v3 rescue batch for R158-R161

Goal: cover the earlier HC60/ESA200/KMB1203/KE-SL-056 baseline batch.

## Results

| Source round | Part | prior error | v3 action | v3 error |
|---|---:|---:|---|---:|
| R158 | KE-SL-052 HC60 motor | -44% | back-calc ID R=13.7443 | -0.3363% |
| R159 | KE-SL-001 ESA200-G | -37% | back-calc ID R=28.2621 | -0.5325% |
| R160 | KMB1203 | -32% | back-calc ID R=13.5651 | -0.1063% |
| R161 | KE-SL-056 | +0.61% | no back-calc | +0.6116% |

## Lesson

The same v3 rule covers HC60 motor sleeve, ESA200-G, and KMB1203, while leaving
KE-SL-056 alone. This strongly supports replacing `auto_ring_v2` with
`auto_ring_v3` as the default sleeve learner.

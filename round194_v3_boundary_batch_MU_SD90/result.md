# Round 194: auto_ring_v3 boundary batch for R170-R173

Goal: test v3 against MU/KMB/SD90 cases and identify remaining boundary cases.

## Results

| Source round | Part | prior error | v3 action | v3 error |
|---|---:|---:|---|---:|
| R170 | MU100 v2 | -0.7% | no back-calc | -0.6926% |
| R171 | KMB1203E | -28% | back-calc ID R=13.4257 | -0.2214% |
| R172 | KE-SL-017 SD90 sleeve | +14% / hidden collar family | back-calc ID R=18.0335 | -0.4752% |
| R173 | SD90 ring | -7% | no back-calc | -7.0549% |

## Lesson

`auto_ring_v3.ps1` remains stable on already-good MU100 and rescues KMB1203E /
SD90 sleeve cases into sub-1%.

R173 exposes a different remaining boundary: small rings can lose too much
volume from the generic `0.5 mm` chamfer. For small OD/thickness rings, chamfer
distance should scale down or be disabled when mass error is mostly caused by
edge treatment rather than bore detection.

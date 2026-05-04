# Round 204: zero-ID fallback and thin-wall chamfer scaling

Problem: R141/R144 ultra-thin large rings had no detected inner cylinder, so
v3 treated them as solid discs and produced catastrophic errors.

## Changes

1. Allow effective-bore back-calc even when detected ID radius is `0`.
2. Scale chamfer by OD, thickness, and wall thickness:
   `min(0.5, max(0.05, min(OD*0.01, thickness*0.10, wall*0.10)))`.

## Verification

| Round | Before | After |
|---|---:|---:|
| R141 tube-2017 | +2599% | -0.9863% |
| R144 tube-2013 | +1355% | -0.9782% |
| R173 SD90 ring | +0.5852% previous scaled chamfer | +1.5243% |
| R189 KE-SL-022 | -0.8462% | -0.0437% |
| R190 KE-SL-024 old | -0.4906% | -0.1872% |

## Lesson

When no inner cylinder is detected, mass-volume back-calc can still infer a
usable effective bore. Ultra-thin flat rings also need chamfer limited by
thickness and wall, not just OD.

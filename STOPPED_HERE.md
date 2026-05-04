# Session Status - R189 Done

**Date**: 2026-05-04
**Total rounds**: 189+  
**Latest local commit before this note**: `352b005`

## Latest Continuation

- Found uncommitted `round189_KE-SL-022/` from the prior run.
- `real.ipt` and `my_attempt_v2.ipt` exist locally, but IPT files are ignored by
  Git. The committed artifact is `round189_KE-SL-022/result.md`.
- R189 result: `KE-SL-022` square sleeve, OD/T = `52 x 52`, real volume
  `9441.3 mm^3`.
- `auto_ring_v2` chose inner radius `24 mm`, but back-calculated real bore is
  about `24.86 mm`. That 0.86 mm radius miss creates `+72.20%` volume error.

## New Failure Pattern

For thin-wall stepped sleeves, the visible/detected cylinder at the smaller seat
is not necessarily the through bore. This is the same family as R184 SDE300C.

Rule to add next:

- If ring wall thickness is close to 1 mm and volume is far below the simple
  OD/ID cylinder estimate, back-calculate the effective bore from mass volume
  before saving the attempt.
- Flag square-format sleeves where `length ~= OD`; these appear often in KE-SL
  parts and can hide stepped bores.

## Pending GitHub Push

`gh` is still not authenticated and no remote is configured. Commits are local
until GitHub auth/token is available.

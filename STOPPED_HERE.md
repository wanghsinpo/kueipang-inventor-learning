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
- Added `auto_ring_v3.ps1` and tested it on R189. It chose effective ID radius
  `24.8638 mm` and reduced error to `-0.8462%`.
- R190 `KE-SL-024 old` tested the opposite failure: detected ID radius too
  large. Bidirectional v3 back-calc improved `-34.38%` to `-0.4906%`.
- R191 batch-tested v3 against R183-R188. Six failures from `-57%..+33%` all
  moved to sub-1% volume error.
- R192 batch-tested v3 against R179-R182. Four A150/ESA200 failures from
  `-45%..-38%` also moved to sub-1%.
- R193 batch-tested v3 against R174-R178. AA/KMB failures moved to sub-1%;
  already-good A70W/GE024 stayed unchanged.
- R194 batch-tested v3 against R170-R173. KMB1203E/SD90 sleeve moved to sub-1%;
  SD90 ring stayed `-7%`, likely from fixed 0.5mm chamfer on a small ring.
- R195 scaled chamfer by OD. SD90 ring improved from `-7.05%` to `+0.585%`;
  large-sleeve R189/R190 outputs stayed unchanged.
- R196 batch-tested v3 against R166-R169. HC60E/ESA300G/EV-X200N moved to
  roughly sub-0.5%; MU100 stayed around 1%.
- R197 batch-tested v3 against R162-R165. ESA300M and HC60 C/D moved to sub-0.5%;
  KE-SL-056 stayed unchanged.
- R198 batch-tested v3 against R158-R161. HC60 motor, ESA200-G, and KMB1203
  moved to sub-0.6%; KE-SL-056 stayed unchanged.
- R199 lowered v3 gate from `15%` to `8%`. R155 improved from `-10.39%` to
  `-1.02%`; known-good MU100/A70W/GE024 did not change.
- R200 summarized R154-R157. Early KE-SL failures from `+140%..-38%` now sit
  around `-1%`.
- R201 checked EV-S200P. BP spacer moved to `-0.95%`; G washer stayed at
  `-4.09%`.
- R202 checked KE-SP/EV-M502. Ring-like spacers improved to roughly `-1.6%..-2.9%`;
  EV-M502 moved to `-0.69%`; tiny pin remains low priority.
- R203 checked KMB oil seals. +18~27% overfills moved to sub-1% mass error.
- R204 added zero-ID fallback and thickness/wall-scaled chamfer. R141/R144
  ultra-thin rings moved from catastrophic `+2599%/+1355%` to about `-0.98%`.
- R205 checked KE-SP-019/flinger2. Spacer improved to `-1.22%`; close flinger
  stayed stable at `+2.15%`.
- R206 checked ESR/EV/AA mix. AA-BP and BP flinger moved below 0.5%; ESR remains
  around `+6%`.

## New Failure Pattern

For thin-wall stepped sleeves, the visible/detected cylinder at the smaller seat
is not necessarily the through bore. This is the same family as R184 SDE300C.

Rule to add next:

- Use `auto_ring_v3.ps1` for thin-wall sleeves: it back-calculates effective
  bore when simple OD/ID volume is far too high.
- Keep the v3 gate bidirectional; both overfilled and underfilled simple rings
  are evidence that detected cylinder radius is not the effective bore.
- Flag square-format sleeves where `length ~= OD`; these appear often in KE-SL
  parts and can hide stepped bores.

## Pending GitHub Push

`gh` is still not authenticated and no remote is configured. Commits are local
until GitHub auth/token is available.

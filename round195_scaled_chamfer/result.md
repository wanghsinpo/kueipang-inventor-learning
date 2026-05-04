# Round 195: scaled chamfer for small rings

Problem from R194: `auto_ring_v3.ps1` used a fixed `0.5 mm` chamfer on all ring
edges. For small rings this removes too much material and can also shrink the
reported bbox height.

## Change

Chamfer distance now scales with OD:

`chamferMm = min(0.5, max(0.1, OD * 0.01))`

Large parts keep the old 0.5 mm chamfer. Small rings get a smaller edge break.

## Verification

| Round | Before | After |
|---|---:|---:|
| R173 SD90 ring | -7.0549% | +0.5852% |
| R170 MU100 v2 | -0.6926% | +1.1021% |
| R189 KE-SL-022 | -0.8462% | -0.8462% |
| R190 KE-SL-024 old | -0.4906% | -0.4906% |

## Lesson

Small rings need scaled chamfers. A fixed 0.5 mm edge treatment is acceptable
for larger KE-SL sleeves but too aggressive for OD around 16-25 mm.

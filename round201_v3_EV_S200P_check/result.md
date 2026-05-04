# Round 201: auto_ring_v3 check on EV-S200P spacer/washer

Goal: see whether v3 applies beyond KE-SL sleeves to EV-S200P spacer and washer
parts.

## Results

| Source round | Part | prior error | v3 action | v3 error |
|---|---:|---:|---|---:|
| R152 | EV-S200P BP v3 | -16% | back-calc ID R=27.6051 | -0.9502% |
| R153 | EV-S200P G washer | -5% | no back-calc | -4.0910% |

## Lesson

v3 can rescue EV-S200P BP spacer-like geometry into the target band. Thin
washers still need a washer-specific template for visual/detail accuracy, but
`-4%` is acceptable for the learning loop's mass/bbox baseline.

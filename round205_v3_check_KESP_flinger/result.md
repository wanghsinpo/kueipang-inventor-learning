# Round 205: auto_ring_v3 check on KE-SP-019 and MP flinger

Goal: test v3 on a KE-SP spacer that was already close and a flinger-like part
that should not be overcorrected.

## Results

| Source round | Part | prior error | v3 action | v3 error |
|---|---:|---:|---|---:|
| R139 | KE-SP-019 EVM | +10% | back-calc ID R=27.5551 | -1.2163% |
| R140 | EV-L200 MP flinger2 | +1.5% / close | no back-calc | +2.1548% |

## Lesson

v3 improves KE-SP spacer mass estimates and does not aggressively rewrite a
close flinger. Flingers still need their own visual/top-hat template for detail,
but v3 is acceptable as a mass baseline.

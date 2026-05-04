# Round 206: auto_ring_v3 check on ESR, EV-L200, and AA-BP cases

Goal: test v3 on a mixed batch of ESR spacer, EV-L200 spacer/flingers, and
AA-BP sleeve.

## Results

| Source round | Part | prior note/error | v3 action | v3 error |
|---|---:|---:|---|---:|
| R134 | KE-SL-010 ESR | +6% | no back-calc | +6.1385% |
| R135 | EV-L200 BP spacer | 0% perfect | no back-calc | +0.9836% |
| R136 | EV-L200 BP flinger | -11% | back-calc ID R=27.6395 | -0.4336% |
| R137 | EV-L200 MP flinger | +2% | no back-calc | +2.2147% |
| R138 | KE-SL-006 AA-BP | -37% | back-calc ID R=22.7881 | -0.2294% |

## Lesson

v3 helps AA-BP and BP flinger mass/bbox estimates while keeping already-good
spacer/flinger cases stable. ESR remains around 6%, which is acceptable for
moving on but may need an ESR-specific visual/detail template later.

# Round 196: auto_ring_v3 rescue batch for R166-R169

Goal: test v3 on HC60/ESA300/MU100/EV-X200N failures after adding
bidirectional bore back-calc and scaled chamfer.

## Results

| Source round | Part | prior error | v3 action | v3 error |
|---|---:|---:|---|---:|
| R166 | KE-SL-051 HC60E | -60% | back-calc ID R=10.4457 | -0.3074% |
| R167 | KE-SL-002 ESA300G | +60% / later simple estimate +209% | back-calc ID R=41.9502 | -0.4630% |
| R168 | MU100 sleeve | -0.70% | no back-calc, scaled chamfer | +1.1021% |
| R169 | EV-X200N MP-M | -99% | back-calc ID R=27.0896 | -0.2940% |

## Lesson

The effective-bore mass match works even on very poor previous failures. For
EV-X200N and ESA300G this is a first-order bbox/volume proxy, not proof that
visual details such as grooves, lips, or non-ring features are correct.

Still, v3 gives a strong training baseline: get the mass and envelope right
first, then layer visual/detail templates later.

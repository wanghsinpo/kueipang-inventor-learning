# Round 199: lower auto_ring_v3 back-calc gate from 15% to 8%

Problem: R155 `KE-SL-009` stayed at `-10.3901%` because the v3 gate only
back-calculated effective bore when simple ring volume differed by more than
15%.

## Change

Back-calc threshold changed from `15%` to `8%`.

## Verification

| Round | Behavior | Result |
|---|---|---:|
| R155 KE-SL-009 | now back-calcs ID R=23.0474 | -1.0209% |
| R170 MU100 v2 | no back-calc | +1.1021% |
| R175 A70W | no back-calc | -1.4695% |
| R176 GE024 MU100 | no back-calc | +3.5055% |
| R189 KE-SL-022 | still back-calcs | -0.8462% |

## Lesson

8% catches medium sleeve misses like R155 while still leaving known-good simple
ring cases alone. This is a better default gate than 15%.

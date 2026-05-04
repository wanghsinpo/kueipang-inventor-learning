# Round 202: auto_ring_v3 check on KE-SP and EV-M502 cases

Goal: see how v3 behaves outside the main KE-SL sleeve family.

## Results

| Source round | Part | prior note/error | v3 action | v3 error |
|---|---:|---:|---|---:|
| R147 | KE-SP-016 P1 | +8% | back-calc ID R=34.6269 | -1.5803% |
| R148 | KE-SP-004 P1 | +9% | back-calc ID R=26.5222 | -2.8883% |
| R149 | KE-SP-004 P2 tiny pin | tiny part / skip | back-calc ID R=2.1621 | -2.4763% |
| R150 | KE-SP-016 P1 duplicate | +8% | back-calc ID R=34.6269 | -1.5803% |
| R151 | EV-M502 MP finger | -43% | back-calc ID R=36.9659 | -0.6901% |

## Lesson

v3 can improve KE-SP ring-like spacers and EV-M502 mass/bbox estimates, but
tiny pin parts should remain low priority because mass matching does not mean
the learned visual geometry is useful.

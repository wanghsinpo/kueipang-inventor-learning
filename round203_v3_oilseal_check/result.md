# Round 203: auto_ring_v3 check on KMB oil seal washers

Goal: test whether v3 effective-bore back-calc fixes oil seal washer cases that
previously overfilled by 18-27%.

## Results

| Source round | Part | prior error | v3 action | v3 error |
|---|---:|---:|---|---:|
| R145 | KMB601 oil seal | +27% | back-calc ID R=22.5682 | -0.8970% |
| R146 | KMB602PT oil seal | +18% | back-calc ID R=22.1067 | -0.7454% |

## Lesson

KMB oil seal washer mass can also be handled by effective-bore v3. Visual seal
lip details are still absent, but bbox/volume is now within the learning-loop
tolerance.

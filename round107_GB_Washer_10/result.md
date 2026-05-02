# Round 107: GB_T 9407.28-1988 Washer 10

- File: `Washer GB_T 9407.28-1988 10.ipt` (181 KB)
- Real: BBox 1×1×11.145mm (oriented along Z!), Vol 36mm³
- OD R=0.5, ID R=0

## Result
- auto_ring_v2: **-77.22%** — orientation mismatch
- The washer's natural axis is X or Y (radial), not Z (auto_ring assumes Z is axis)
- BBox X=Y=1mm wrong → suggests part oriented with thickness along X/Y axis
- Lesson: auto_ring needs to detect axis direction from largest cyl face normal,
  not assume Z-aligned

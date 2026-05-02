# Round 125: KE-SL-052 HC60 Motor Sleeve

- File: `KE-SL-052-HC60-motor sleeve.ipt` (221 KB)
- Real: BBox 33×33×23.5mm, Vol 6154.8mm³
- OD R=16.5, ID R=15 (thin outer wall ~1.5mm detected)
- Spec from PDF: φ33*φ25.05*23.5t → OD=33, ID=25.05, L=23.5

## Result
- auto_ring_v2: **-44.13%** — thin wall detected instead of full bore
- Detected ID=15 (wall=1.5mm) vs spec ID=25.05 (wall=4mm)
- Theoretical with spec ID: π*(16.5²-12.525²)*23.5 = π*(272.25-156.9)*23.5 = 8521mm³
- Real=6154mm³ → still 28% off from spec dimensions → additional geometry
- KASHIYAMA HC60 motor sleeve series: complex stepped bore pattern

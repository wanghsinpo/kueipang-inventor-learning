# Round 160: KMB1203 Sleeve OD=38 T=50

- File: `KMB1203 sleeve.ipt` (198 KB)
- Real: BBox 38×38×50mm, Vol 27801.2mm³
- OD R=19, ID R=15.515 (detected — wall=3.485mm)

## Result
- auto_ring_v2: **-32.23%** — thin collar detection fail (similar to KMB1201/1202)
- Back-calc actual bore: π*(361-r²)*50 = 27801.2 → r ≈ 13.56mm
- Detected R=15.515 vs actual R≈13.56mm — 3.5mm collar at OD misleads
- KMB1203 different from KMB1201/1202 (+200%): here bore IS detected (not solid-disc fail)
- But the detected radius is still the outer collar face, not the actual shaft bore
- KMB1203: -32% (different failure mode from KMB1201/1202)
- NEW: KMB1203 has detectable collar, but actual bore R=13.56mm hidden inside shaft seat

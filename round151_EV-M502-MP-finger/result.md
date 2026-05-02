# Round 151: EV-M502 MP Finger (KE-SL-059) OD=81 T=20.5

- File: `EV-M502 MP Finger.ipt` (209 KB)
- Real: BBox 81×81×20.5mm, Vol 17631.8mm³
- OD R=40.5, ID R=38.5 (detected — thin wall=2mm)

## Result
- auto_ring_v2: **-42.99%** — thin outer wall detected, ESA-type fail
- Detected ID R=38.5 (wall=2mm) → my vol = 10051.5mm³
- Back-calculate real ID: π*(1640.25-r²)*20.5 = 17631.8 → r ≈ 36.96mm
- Actual bore R≈36.96mm (wall=3.54mm) vs detected R=38.5mm (wall=2mm)
- EV-M502 "Finger" = flinger/sleeve with thin outer collar, ESA-type geometry
- KE-SL-059: OD=81mm — larger than EV-L200-MP Flinger (OD=49mm, +1.5%)
- "Finger" style parts: larger OD, thicker body, thin outer collar always misleads


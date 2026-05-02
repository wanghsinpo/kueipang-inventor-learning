# Round 173: AP1-SD90VIII 從動齒輪軸心套環 OD=16 T=10

- File: `AP1-SD90VIII從動齒輪軸心套環.ipt` (96 KB)
- Real: BBox 16×16×10mm, Vol 239.6mm³
- OD R=8, ID R=7.5 (detected — wall=0.5mm??)

## Result
- auto_ring_v2: **-7.05%** — chamfer oversubtraction on small thin ring
- Detected wall=0.5mm is very thin, but bore ID R=7.5 seems correct
- Pure ring: π*(64-56.25)*10 = 243.5mm³ vs real 239.6mm³ → +1.6% base  
- With chamfers on OD=16mm tiny part: 222.7mm³ → -7.05%
- Very small ring (OD=16mm) → 0.5mm chamfer removes disproportionate % of volume
- Back-calc: π*(64-r²)*10 = 239.6 → r = 7.56mm (actual bore very close to detected 7.5mm)
- Bore detection is CORRECT; failure is chamfer over-subtraction on tiny OD=16mm ring
- LESSON: OD<20mm rings: chamfer removes ~7% (similar to thin T<3mm washer effect)

# Round 184: KE-SL-012 SDE300C Sleeve OD=84 T=47.5

- File: `KE-SL-012-SDE300C-SLEEVE.ipt` (323 KB)
- Real: BBox 84×84×47.5mm, Vol 60649.2mm³
- OD R=42, ID R=34.95 (detected — wall=7.05mm)
- Bolt holes filtered: R=2.55, R=1.621

## Result
- auto_ring_v2: **+33.28%** — bore too small detected
- Pure ring with detected R=34.95: π*(1764-1221.5)*47.5 = 80,992mm³ → +33.5% base
- Back-calc actual bore: π*(1764-r²)*47.5 = 60649 → r ≈ 36.84mm
- Detected R=34.95 vs actual bore R≈36.84mm — detected TOO SMALL by 1.89mm!
- OPPOSITE of normal failure: usually detect too-large collar; here detect smaller bearing seat
- SDE300C has stepped bore: R=34.95mm bearing seat + R=36.84mm main bore opening
- Main bore R=36.84mm likely has non-cylindrical faces (chamfered/tapered) → not detected
- SDE300C: new failure mode — stepped bore where smaller bearing seat is detected, not main bore

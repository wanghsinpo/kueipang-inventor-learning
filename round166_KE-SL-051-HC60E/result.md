# Round 166: KE-SL-051 HC60-E Sleeve OD=32 T=12

- File: `KE-SL-051-HC60-E.0002.ipt` (189 KB)
- Real: BBox 31.98×31.98×12mm, Vol 5525.5mm³
- OD R=15.99, ID R=14 (detected — wall=1.99mm), bolt hole R=1.621 filtered

## Result
- auto_ring_v2: **-60.13%** — ultra-thin collar detection fail
- Back-calc actual bore: π*(255.68-r²)*12 = 5525.5 → r ≈ 10.45mm
- Detected R=14 vs actual bore R≈10.45mm — 2mm outer sealing collar hides deep bore
- HC60-E pattern: OD=32mm, thin 2mm outer collar at R=14, shaft bore at R=10.45mm
- HC60 family summary: C (-73%), D (+54%), E (-60%) — all fail differently
- HC60-E: thin collar → -60% underestimate (between C and D)

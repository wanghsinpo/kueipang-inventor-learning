# Round 176: GE-024 MU-100 粗加工 (Rough Machining) OD=63.9 T=15

- File: `GE-024-MU-100-粗加工.ipt` (124 KB)
- Real: BBox 63.9×63.9×15mm, Vol 40901mm³
- OD R=31.95, ID R=11 (detected — wall=20.95mm!)
- Bolt hole radii filtered: R=9, R=1.621

## Result
- auto_ring_v2: **+3.51%** — good match!
- Pure ring: π*(1020.8-121)*15 = 42,404mm³ → +3.7% before chamfers
- With chamfers: 42,335mm³ → +3.51%
- Rough machining blank: wide ring with small bore (OD=63.9, bore=22mm)
- 8 bolt holes at R=9mm filtered correctly (R=9 < 30% of 31.95 = 9.59mm)
- Very wide wall (20.95mm) means bore detection at R=11 is accurate
- Small bolt holes contribute ~3.5% volume overcount (8 holes × ~180mm³ each)
- GE-024 rough blank: +3.51% (close to KE-SP bolt-hole family pattern)

# Round 126: KE-SL-053 油封墊片 T=7.5 OD=62 (Kashiyama Oil Seal Washer)

- File: `KM-20140709-07-Kashiyama 機械油封墊片(T=7.5-外徑62).ipt` (137 KB)
- Real: BBox 62×62×7.5mm, Vol 11185.4mm³
- OD R=31, ID R=20

## Result
- auto_ring_v2: **+17.46%** — close but overestimate
- My ring: π*(31²-20²)*7.5 = π*561*7.5 = 13222mm³ vs real 11185mm³
- Expected ID if uniform: 11185/(π*7.5) + 20² = 474.6+400 = 874.6 → r=29.57mm — but detected 20mm
- Real ID might be ~29.6mm (very thin wall ~1.4mm), or part has stepped inner bore
- Oil seal washer type: inner bore larger than detected, some hidden geometry

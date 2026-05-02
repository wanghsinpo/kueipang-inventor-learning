# Round 141: 套管 2017 Large Thin Disc OD=326 T=1.5

- File: `套管.ipt` (82 KB, 2017)
- Real: BBox 326×326×1.5mm, Vol 4629.2mm³
- OD R=163, ID R=0 (filtered — not detected)

## Result
- auto_ring_v2: **+2599%** — catastrophic fail, extreme thin ring
- This is a 326mm OD flat disc/ring that is only 1.5mm thick
- Back-calculate inner bore: π*(163²-r²)*1.5 = 4629 → r ≈ 162.1mm (wall=0.9mm!)
- Sub-1mm wall ring — inner bore essentially same OD as outer bore
- auto_ring detects no valid inner bore (ID=0) → treated as solid disc
- Solid disc vol: π*163²*1.5 = 125385mm³ >> real 4629mm³
- NEW failure pattern: ultra-thin-wall large ring (wall<1mm) — ID not detectable
- This is likely a precision ground thin ring/washer, not a machined sleeve


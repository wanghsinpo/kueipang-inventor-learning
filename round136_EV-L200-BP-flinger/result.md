# Round 136: EV-L200-BP Flinger (隔油器) OD=62 T=15.5

- File: `EV-L200-BP Flinger.ipt` (171 KB)
- Real: BBox 62×62×15.5mm, Vol 9595.7mm³
- OD R=31, ID R=28 (detected — thin wall ~3mm)

## Result
- auto_ring_v2: **-11.14%** — underestimate, actual bore slightly smaller
- Detected ID R=28 (wall=3mm) → my vol = 8526.3mm³
- Back-calculate real ID: π*(961-r²)*15.5 = 9595.7 → r² = 961-197.1 = 763.9 → r ≈ 27.6mm
- Actual bore ~R=27.6mm vs detected R=28mm (0.4mm difference)
- Flinger (隔油器) has thin outer lip/groove at R=28 that's detected instead of bore
- Similar to R133 EV-S200P (-14.54%): same failure mode, thin outer feature detected
- EV-L200-BP Flinger family: detected thin collar, bore is slightly smaller


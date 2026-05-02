# Round 133: EV-S200P BP Sleeve

- File: `EV-S200P BP.ipt` (171 KB)
- Real: BBox 62×62×15.5mm, Vol 9657.3mm³
- OD R=31, ID R=28.1 (detected — thin wall ~2.9mm)

## Result
- auto_ring_v2: **-14.54%** — underestimate, actual bore slightly smaller than detected
- Detected ID R=28.1 (wall=2.9mm) → my vol ≈ 8252.9mm³
- Back-calculate real ID: π*(961-r²)*15.5 = 9657 → r² = 961-198.4 = 762.6 → r ≈ 27.62mm
- Actual inner bore ~R=27.6mm (wall=3.4mm) vs detected R=28.1mm (wall=2.9mm)
- 0.5mm difference in detected vs actual ID causes -14.5% error
- Likely a thin outer feature (lip/seal groove) at R=28.1 that is detected instead of main bore
- EV-S200P oil seal family: has thin outer collar/groove that fools ID detection
- Compare to KE-SL-056 (R128, +0.61%): also thin-wall but that one was truly uniform → PERFECT
- EV-S200P has outer feature at R=28.1 but real bore is R=27.6 → thin collar detected instead of bore


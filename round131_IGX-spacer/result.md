# Round 131: IGX間隔環 (IGX Spacer Ring)

- File: `IGX間隔環.ipt` (137 KB)
- Real: BBox 61.3×61.3×10.61mm, Vol 18635.1mm³
- OD R=30.65, ID R=28 (detected — thin outer wall ~2.65mm)

## Result
- auto_ring_v2: **-72.69%** — inverted detection: detected thin outer wall, real bore is smaller
- Detected ID R=28 (wall=2.65mm) → my vol = π*(30.65²-28²)*10.61 ≈ 5088mm³
- Real vol=18635mm³ → back-calculate real ID: π*(939.4-r²)*10.61=18635 → r≈19.5mm
- Actual inner bore ~R=19.5mm (diam~39mm), not R=28mm
- The R=28 cylinder is likely a bolt circle pattern or counterbore lip, not the main bore
- This is a NEW failure pattern: detected cylinder is a feature, not the bore
- Unlike ESA (outer thin wall detected, inner bore hidden), here outer thin ring detects wrong
- Volume is MUCH larger than ring model → real part is much more solid (smaller bore)
- IGX spacer ring family: complex geometry with features at R=28 masking true bore


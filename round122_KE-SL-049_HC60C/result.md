# Round 122: KE-SL-049 HC60-C (KASHIYAMA φ43.5*φ25.05*31t)

- File: `KE-SL-049-HC60-C.ipt` (240 KB)
- Real: BBox 31×31×43.5mm (SIDE ORIENTATION!), Vol 11578.2mm³
- Script read: OD R=15.5 (BBox/2), thick=43.5 — WRONG axis
- Spec: OD=43.5mm, ID=25.05mm, L=31mm

## Result
- auto_ring_v2: **-73.22%** — part stored on its side (Z=diameter, not length)
- Same "axis rotation" problem as R107 GB Washer
- Correct approach: if thick > BBox, swap: OD=thick/2, length=BBox
- Corrected theoretical vol: π*(21.75²-12.525²)*31 = π*(473.1-156.9)*31 = 30773mm³ — but real is 11578
- Even with correct axis, large volume mismatch → complex internal geometry (KASHIYAMA DP)
- Skip: axis issue + complex geometry

# Round 222: EV-X200N-MP-M Sleeve Jan 2026 OD=70 T=21.5

- File: `EV-X200N-MP-M.ipt` (254 KB, Jan 2026)
- Real: BBox 70×70×21.5mm, Vol 33174.5mm³
- OD R=35, ID R=34.9 (detected — wall=0.1mm ultra-thin collar!)

## Result
- auto_ring_v3: **-0.2940%** ✓ — back-calc fixed -98.58% simple diff
- Detected ID R=34.9 (only 0.1mm wall detected!), back-calc R=27.09
- Ultra-thin outer collar: virtually the entire OD is just the thin ring face
- Simple diff was -98.58% — near-complete miss before back-calc
- v3 handles even near-zero wall thickness: mass-based back-calc is robust
- Jan 2026 revision: same pass as prior version from round169/196 tests

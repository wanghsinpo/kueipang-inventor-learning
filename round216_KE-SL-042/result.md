# Round 216: KE-SL-042 MU600 BP Sleeve OD=47.5 T=47.5 (square)

- File: `KE-SL-042-MU600_BP_SLEEVE.ipt` (262 KB)
- Real: BBox 47.5×47.5×47.5mm, Vol 8676.2mm³
- OD R=23.75, ID R=21.7 (detected — wall=2.05mm)

## Result
- auto_ring_v3: **-0.0529%** ✓ — back-calc fixed +60.25% simple diff
- Detected ID R=21.7, back-calc ID R=22.49 (opposite: detected bore TOO SMALL)
- Square-format sleeve (T=OD=47.5mm) — same geometry class as KE-SL-022
- +60% simple diff: stepped bore, smaller bearing seat detected instead of main bore
- Same SDE300C/KE-SL-022 pattern: back-calc corrects upward from too-small bore
- v3 bidirectional back-calc: works perfectly (-0.05%)

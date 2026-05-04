# Round 218: SL-057-KMB1201 Sleeve OD=78.1 T=15

- File: `SL-057-KMB1201-sleeve.ipt` (125 KB, Dec 2024)
- Real: BBox 78.1×78.1×15mm, Vol 14546.3mm³
- OD R=39.05, ID R=22.25 (detected — only small inner bore found)

## Result
- auto_ring_v3: **-0.5568%** ✓ — back-calc fixed +233.62% simple diff
- Detected ID R=22.25 (shaft bore, not sleeve bore!), back-calc R=34.87
- KMB1201 2024 redesign: flat disc-like sleeve (T=15mm, thin compared to OD=78mm)
- Inner bore at R=22.25 is the shaft hole; sleeve bore much larger at R≈34.87
- Same KMB1201 family as KE-SL-038 but different geometry (disc vs cylinder)
- v3 back-calc: handles completely undetected sleeve bore (+233% → -0.56%)

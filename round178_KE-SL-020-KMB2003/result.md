# Round 178: KE-SL-020 KMB2003 Sleeve OD=95 T=43.2

- File: `KE-SL-020-KMB2003 SLEEVE.ipt` (175 KB)
- Real: BBox 95×95×43.2mm, Vol 44100.4mm³
- OD R=47.5, ID R=45.5 (detected — wall=2mm)

## Result
- auto_ring_v2: **-43.09%** — thin collar detection fail
- Back-calc actual bore: π*(2256.25-r²)*43.2 = 44100.4 → r ≈ 43.95mm
- Detected R=45.5 vs actual bore R≈43.95mm — 2mm outer collar detected
- KMB2003 is a large sleeve (OD=95mm), but same thin-collar failure as KMB1201-1203
- KMB family -28~-43%: larger OD → more severe underestimate (more volume in collar region)
- New: KMB2003 (OD=95mm) gives -43% vs KMB1203 (OD=38mm) -32% — larger OD = worse

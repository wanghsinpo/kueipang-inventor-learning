# Round 245: IGX Spacer Ring OD=61.3 T=10.61 (Nov 2025)

- File: `IGX間隔環.ipt` (137 KB, Nov 2025)
- Real: BBox 61.3×61.3×10.61mm, Vol 18635.076mm³
- OD R=30.65, ID R=28 (detected — wall=2.65mm)

## Result
- auto_ring_v3: **-0.4228%** ✓ — back-calc fixed -72.20% simple diff
- Detected ID R=28 (too large — thin outer collar), back-calc R=19.50 (8.50mm gap)
- IGX間隔環 = IGX spacer ring (Nov 2025 revision)
- OD=61.3mm, T=10.61mm — similar OD range to KMB spacers but thicker
- Detected ID R=28 is near OD R=30.65 (wall=2.65mm collar) → ultra-thin collar detection
- v3 back-calc corrects -72% → -0.42% — same thin collar mechanism as EV-family
- IGX pump: uses thin-collar spacer ring, v3 handles it reliably

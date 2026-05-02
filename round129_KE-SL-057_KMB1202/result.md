# Round 129: KE-SL-057 KMB1202 SLEEVE

- File: `SL-057-KMB1202-sleeve.ipt` (125 KB)
- Real: BBox 78.1×78.1×15mm, Vol 14546.3mm³
- OD R=39.05, ID R=22.25 (detected — likely wrong)

## Result
- auto_ring_v2: **+232.96%** — same failure mode as KE-SL-038 (R117, +207%)
- KMB1202 same issue as KMB1201: wrong inner bore detection
- Expected ID: π*(39.05²-r²)*15=14546 → r²=1524.9-308.8=1216.1 → r≈34.87mm
- Real inner bore ~R=35mm not detected; detected R=22.25 (false cylinder from feature)
- KMB1201/1202 family: consistently +200% due to wrong ID, inner bore ~35mm undetected

# Round 295: Spacer (128K) OD=20 T=80 — FAIL

- File: `spacer.ipt` (128512 bytes, Nov 2025)
- Real: BBox 20×20×80mm, Vol 23817.332mm³
- OD R=10, ID R=0 (detected, no bore)

## Result
- auto_ring_v3: **+5.5124%** ✗ — solid cylinder or complex geometry
- BBox 20×20×80mm = very tall thin rod (OD=20, T=80, T/OD=4x)
- ID=0 = no cylindrical bore detected → ring model not applicable
- Likely a solid shaft/pin spacer, not a hollow ring
- FAIL: +5.5% outside ±2% threshold

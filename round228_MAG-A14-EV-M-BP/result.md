# Round 228: MAG-A14-EV-M BP Magnet Housing OD=104.9 T=119.7

- File: `MAG-A14-EV-M BP.ipt` (206 KB, Jun 2025)
- Real: BBox 104.9×104.9×119.7mm, Vol 73367.6mm³
- OD R=52.45, ID=0 (no bore cylinder detected)

## Result
- auto_ring_v3: **-0.0316%** ✓ — zero-ID fallback + back-calc fixed +1310% simple diff
- No bore face detected (ID=0) → back-calc effective bore R=50.56mm
- Large magnet housing: barrel shape (T=119.7 > OD=104.9mm)
- Only outer surface detected; bore is complex (non-cylindrical or too large to detect)
- v3 zero-ID + back-calc: near-perfect for large barrel parts (-0.03%)
- MAG-A14 family: OD≈105mm barrel — v3 handles this gracefully

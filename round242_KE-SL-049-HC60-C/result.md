# Round 242: KE-SL-049 HC60-C Bush OD=43.5 T=43.5 (Feb 2025)

- File: `KE-SL-049-HC60-C.ipt` (239 KB, Feb 2025)
- Real: BBox 43.5×43.5×43.5mm, Vol 11578.151mm³
- OD R=21.75, ID R=21.75 (detected = OD — simple diff=-100%)

## Result
- auto_ring_v3: **-0.0940%** ✓ — back-calc fixed -100% simple diff
- Detected bore = OD (outer cylinder only detected), back-calc R=19.71 (2.04mm gap)
- Cubic proportions: OD=T=43.5mm — square-section bushing/liner
- Simple diff=-100% because detected ID=OD means "hollow cylinder" (zero wall)
- Back-calc correctly recovers effective bore R=19.71 from volume
- HC60-C variant of KE-SL-049 series — "C" = inner configuration?
- v3 handles degenerate ID=OD detection gracefully: -0.09%

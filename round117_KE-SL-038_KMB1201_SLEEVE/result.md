# Round 117: KE-SL-038 KMB1201 SLEEVE

- File: `KMB 1201 sleeve.ipt` (113 KB)
- Real: BBox 75×75×15mm, Vol 13917.1mm³
- OD R=37.5, ID R=22.25 (detected — likely wrong)

## Result
- auto_ring_v2: **+207.86%** — inner bore detection error
- Detected ID=22.25 (should be ~33-34mm based on real volume)
- Real volume=13917 with solid disc area π*37.5²*15=66278 → fill=21%
- Expected ID if uniform ring: π*(37.5²-r²)*15=13917 → r²=37.5²-13917/(π*15) = 1406-295 = 1111 → r≈33.3mm
- The large inner bore (r~33mm) likely not detected as clean cylinder face
- This is a different failure mode: inner bore larger than filter threshold but face not detected

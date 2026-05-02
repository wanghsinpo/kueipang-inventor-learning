# Round 172: KE-SL-017 SD90/120 Sleeve OD=41 T=41

- File: `KE-SL-017-SD90_120.ipt` (128 KB)
- Real: BBox 41×41×41mm, Vol 12771.6mm³
- OD R=20.5, ID R=17.5 (detected — wall=3mm)

## Result
- auto_ring_v2: **+14.50%** — bore over-detection (slight), but mainly non-ring features
- Back-calc actual bore: π*(420.25-r²)*41 = 12771.6 → r ≈ 17.92mm
- Detected R=17.5 vs actual bore R≈17.92mm — slight overcounting (0.4mm off)
- Pure ring at R=17.5: 14,685mm³ vs real 12,772mm³ → +14.9% base
- The bore ID is slightly underestimated (actual 17.92 vs detected 17.5)
- SD90/120 sleeve (OD=41mm, T=41mm, square ring shape): has keyway or stepped features
- Similar to KE-SP family (+7-14%): the ring overestimates due to material removal features
- SD90/120 sleeve: +14.50% (keyway/bolt holes remove material not captured by ring model)

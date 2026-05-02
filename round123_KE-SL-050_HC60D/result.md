# Round 123: KE-SL-050 HC60-D

- File: `KE-SL-050-HC60-D.ipt` (229 KB)
- Real: BBox 18.8×18.8×32mm, Vol 5754.7mm³
- OD R=9.4, ID R=0 (solid disc — no inner bore detected)

## Result
- auto_ring_v2: **+54.11%** — solid disc detected, real part has inner bore
- My solid disc V=π*9.4²*32=8868mm³ vs real 5754mm³
- Fill ratio=5754/(π*9.4²*32)=64.9% → inner bore should exist
- Expected ID: π*(9.4²-r²)*32=5754 → r²=88.36-57.2=31.16 → r≈5.58mm
- Inner bore R≈5.58mm < 30% of OD R=9.4 (2.82mm threshold) → filtered OUT by v2!
- The 30% filter is too aggressive for small parts; inner bore is only ~59% of OD

LESSON: For small OD parts, inner bore may be less than 30% OD and get filtered incorrectly.
Should lower threshold to 20% for parts with BBox < 30mm.

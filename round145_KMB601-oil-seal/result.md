# Round 145: KMB601 機械油封墊片 T=7.5 OD=60

- File: `KMB601機械油封墊片(T=7.5-外徑60).ipt` (139 KB)
- Real: BBox 60×60×7.5mm, Vol 9205.1mm³
- OD R=30, ID R=20 (detected)

## Result
- auto_ring_v2: **+27.13%** — oil seal washer family overestimate
- Detected ID R=20, but actual bore larger: π*(900-r²)*7.5=9205 → r≈22.57mm
- Same family as R126 KE-SL-053 (+17.46%): oil seal washer with larger actual bore
- KMB601 (OD=60) vs KE-SL-053 (OD=62): both have detected R=20 but actual ~R=22.5
- Kashiyama oil seal washer family: consistently overestimates +17~+27% due to bore detection
- Real inner bore is stepped/obscured, detected R=20 cylinder is inner lip not main bore


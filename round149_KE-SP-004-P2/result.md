# Round 149: KE-SP-004-P2 (Small Pin Component) OD=5 T=2.4

- File: `KE-SP-004-P2.ipt` (160 KB)
- Real: BBox 5×5×2.4mm, Vol 11.8mm³
- OD R=2.5, ID R=1.2 (detected)

## Result
- auto_ring_v2: **+156.78%** — wrong component type
- P2 = second part in KE-SP-004 assembly = tiny dowel pin or small fastener component
- Part is only 5mm diameter, 2.4mm thick — NOT the main spacer ring
- KE-SP-004 assembly has P1=spacer ring (done R148) and P2=this tiny component
- "P-series" lesson: P1 = main ring, P2+ = small pins/screws/dowels in assembly
- Skip P2, P3 etc. parts — not meaningful for ring model comparison
- My vol=30.3 vs real=11.8 due to detected ID R=1.2, actual bore larger


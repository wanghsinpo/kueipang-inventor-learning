# Round 190: KE-SL-024 old sleeve

- Real: BBox `55 x 55 x 33 mm`, volume `16621.025 mm^3`
- Initial v3 one-way gate kept detected ID R=`25.5000`
- That produced volume `10906.039 mm^3`, diff `-34.3841%`

## Redo with bidirectional auto_ring_v3 gate

- Updated v3 to back-calculate effective bore when simple ring volume is too
  high or too low by more than 15%.
- Effective ID R back-calculated to `24.4116 mm`.
- Result: volume `16539.482 mm^3`, diff `-0.4906%`.

## Lesson

The same mass-volume back-calc fixes both directions:

- R189: detected bore too small -> huge positive volume error.
- R190: detected bore too large -> huge negative volume error.

Use effective bore whenever detected OD/ID ring volume differs from real mass
volume by more than 15%.

# Round 197: auto_ring_v3 rescue batch for R162-R165

Goal: test v3 on KE-SL-056, ESA300M, and HC60 C/D after scaled chamfer.

## Results

| Source round | Part | prior error | v3 action | v3 error |
|---|---:|---:|---|---:|
| R162 | KE-SL-056 v2 | +0.53% | no back-calc | +0.5337% |
| R163 | KE-SL-003 ESA300M | +139% | back-calc ID R=41.5941 | -0.3604% |
| R164 | KE-SL-050 HC60D | +54% | back-calc ID R=14.0936 | -0.3357% |
| R165 | KE-SL-049 HC60C | -73% | back-calc ID R=19.7063 | -0.4257% |

## Lesson

v3 leaves known-good KE-SL-056 alone and rescues ESA300/HC60 variants into
sub-0.5% mass matches. HC60 C/D/E are now covered by the same effective-bore
strategy.

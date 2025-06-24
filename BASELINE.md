============================================
BASELINE BENCHMARK RESULTS SUMMARY
============================================

Test Name                                    | Avg Time (ms) | Min (ms) | Max (ms)
--------------------------------------------------------------------------
avx.avx_x1                                   |        22.965 |   22.642 |   23.356
avx.avx_x16                                  |         1.107 |    1.091 |    1.126
avx.avx_x1_one_at_time                       |        23.034 |   22.684 |   23.462
avx.avx_x4                                   |         7.472 |    7.362 |    7.615
avx.avx_x8                                   |         3.873 |    3.823 |    3.939
generic.generic                              |        16.390 |   16.095 |   16.893
shani.shani                                  |         2.306 |    2.271 |    2.350
shani.shani_one_at_time                      |         4.008 |    3.944 |    4.074
sse.sse_x1                                   |        15.396 |   15.173 |   15.675
sse.sse_x1_one_at_time                       |        15.522 |   15.284 |   15.796

============================================
GROUPED BY IMPLEMENTATION TYPE
============================================

GENERIC:
  Average: 16.390 ms

SSE:
  sse.sse_x1_one_at_time                15.522 ms
  sse.sse_x1                            15.396 ms

AVX:
  avx.avx_x1_one_at_time                23.034 ms
  avx.avx_x1                            22.965 ms
  avx.avx_x4                             7.472 ms
  avx.avx_x8                             3.873 ms
  avx.avx_x16                            1.107 ms

SHA-NI:
  shani.shani                            2.306 ms
  shani.shani_one_at_time                4.008 ms

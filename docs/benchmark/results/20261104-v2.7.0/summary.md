# L3 device summary

- device: iPhone_16 (iOS_26.6.1_23G83), impeller, 60Hz, budget 16.67ms
- target: `2.7.0` (`d321be9305`), 2 runs
- baseline: `2.6.1` (`47ce52b9ad`), 2 runs
- Flutter 3.47.5, profile build; values are medians over windows, in ms
- percentiles use nearest rank, medians over an even count take the upper one; `op p50` is accurate to about one frame; `noise` is the relative spread of p90 between runs of the same version, `~` marks a difference within it; `RSS MB` is the process RSS at the end of each window and includes heap left by earlier scenarios, `ΔRSS MB` subtracts the RSS measured before the scenario mounted (no forced GC, approximate)

| scenario | build p90 | raster p90 | raster p99 | worst | over budget | op p50 | RSS MB | ΔRSS MB | frames | noise |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| pan/base | 1.54 → 1.54 ~ | 0.96 → 0.96 ~ | 1.02 → 1.02 | 1.88 → 1.90 | 0.0% → 0.0% | - | 87 → 88 | 14 → 15 | 370 → 370 | 3.9% |
| pan/full | 4.52 → 4.58 ~ | 1.26 → 1.28 ~ | 1.35 → 1.42 | 5.53 → 5.54 | 0.0% → 0.0% | - | 94 → 95 | 4 → 4 | 370 → 369 | 7.8% |
| fling/full | 4.14 → 4.16 ~ | 1.23 → 1.21 ~ | 1.37 → 1.31 | 5.10 → 5.33 | 0.0% → 0.0% | - | 98 → 97 | 3 → 0 | 384 → 384 | 9.6% |
| scale/full | 3.66 → 3.69 ~ | 2.14 → 2.08 ~ | 2.92 → 2.91 | 5.75 → 5.38 | 0.0% → 0.0% | - | 102 → 103 | 2 → 3 | 366 → 366 | 7.6% |
| zoom/full | 3.50 → 3.48 ~ | 1.59 → 1.56 ~ | 1.72 → 1.67 | 3.82 → 4.08 | 0.0% → 0.0% | - | 106 → 105 | 1 → -1 | 366 → 366 | 2.6% |
| cross/full | 4.68 → 4.63 ~ | 1.50 → 1.47 | 1.80 → 1.76 | 5.80 → 5.73 | 0.0% → 0.0% | - | 110 → 111 | 6 → 7 | 472 → 472 | 1.6% |
| resize/full | 3.42 → 3.48 ~ | 1.58 → 1.54 ~ | 1.67 → 1.67 | 4.26 → 4.37 | 0.0% → 0.0% | - | 113 → 114 | 2 → 2 | 471 → 471 | 4.0% |
| realtime/full | 3.00 → 3.01 ~ | 1.66 → 1.63 ~ | 1.77 → 1.70 | 5.03 → 4.63 | 0.0% → 0.0% | - | 113 → 114 | -1 → -0 | 363 → 362 | 2.6% |
| startup/full | 0.58 → 0.54 ~ | 1.57 → 1.58 ~ | 1.78 → 1.67 | 11.66 → 11.23 | 0.0% → 0.0% | 30.49 → 30.53 | 116 → 118 | 2 → 1 | 390 → 390 | 23.3% |
| switch/full | 0.59 → 0.56 ~ | 1.46 → 1.40 ~ | 1.56 → 1.48 | 3.41 → 3.42 | 0.0% → 0.0% | 13.92 → 13.97 | 121 → 122 | 5 → 2 | 366 → 366 | 7.3% |
| history/full | 4.37 → 4.43 ~ | 1.25 → 1.27 ~ | 1.38 → 1.42 | 5.35 → 5.23 | 0.0% → 0.0% | 14.24 → 14.86 | 117 → 122 | -1 → -5 | 370 → 370 | 3.8% |
| indicators/full | 0.57 → 0.55 ~ | 1.61 → 1.57 ~ | 1.72 → 1.65 | 4.50 → 4.72 | 0.0% → 0.0% | 15.23 → 15.16 | 116 → 121 | -6 → -4 | 366 → 366 | 5.0% |
| memory/full | 4.48 → 4.51 ~ | 1.28 → 1.26 | 1.36 → 1.35 | 5.59 → 5.48 | 0.0% → 0.0% | - | 124 → 130 | 6 → 7 | 370 → 370 | 0.9% |
| draw/base | 3.71 → 3.70 ~ | 1.18 → 1.06 ~ | 1.41 → 1.25 | 4.89 → 4.34 | 0.0% → 0.0% | - | 121 → 127 | -12 → -11 | 370 → 370 | 20.3% |

Each cell is `baseline → target`; `frames` is frames per window, `!` marks a difference above 10% (the two versions drew a different amount of work).
# L3 device summary

- device: PLZ110 (Android_17), impeller, 60Hz, budget 16.67ms
- target: `2.7.0` (`d321be9305`), 2 runs
- baseline: `2.6.1` (`47ce52b9ad`), 2 runs
- Flutter 3.47.5, profile build; values are medians over windows, in ms
- percentiles use nearest rank, medians over an even count take the upper one; `op p50` is accurate to about one frame; `noise` is the relative spread of p90 between runs of the same version, `~` marks a difference within it; `RSS MB` is the process RSS at the end of each window and includes heap left by earlier scenarios, `ΔRSS MB` subtracts the RSS measured before the scenario mounted (no forced GC, approximate)

| scenario | build p90 | raster p90 | raster p99 | worst | over budget | op p50 | RSS MB | ΔRSS MB | frames | noise |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| pan/base | 1.96 → 1.94 ~ | 2.47 → 2.24 | 2.62 → 2.51 | 2.72 → 2.70 | 0.0% → 0.0% | - | 261 → 262 | 18 → 17 | 370 → 371 | 7.7% |
| pan/full | 6.12 → 5.86 ~ | 2.86 → 2.78 ~ | 3.46 → 3.45 | 7.44 → 7.39 | 0.0% → 0.0% | - | 269 → 271 | 7 → 8 | 372 → 371 | 8.3% |
| fling/full | 5.68 → 5.73 ~ | 2.17 → 2.17 ~ | 3.02 → 3.09 | 7.21 → 7.29 | 0.0% → 0.0% | - | 274 → 276 | 5 → 3 | 384 → 385 | 1.8% |
| scale/full | 4.43 → 4.92 ~ | 3.21 → 3.19 ~ | 5.02 → 5.04 | 7.30 → 7.51 | 0.0% → 0.0% | - | 284 → 285 | 9 → 9 | 366 → 366 | 13.6% |
| zoom/full | 3.96 → 4.05 ~ | 3.08 → 2.97 | 3.49 → 3.37 | 5.08 → 5.23 | 0.0% → 0.0% | - | 286 → 288 | 1 → 1 | 366 → 366 | 3.4% |
| cross/full | 5.76 → 5.77 ~ | 3.31 → 3.39 | 3.84 → 3.83 | 6.83 → 7.07 | 0.0% → 0.0% | - | 289 → 291 | 3 → 3 | 366 → 366 | 2.4% |
| resize/full | 4.33 → 4.38 ~ | 2.89 → 2.83 | 3.38 → 3.36 | 5.78 → 5.91 | 0.0% → 0.0% | - | 292 → 294 | 1 → 2 | 471 → 471 | 1.8% |
| realtime/full | 3.93 → 3.98 ~ | 3.15 → 3.27 | 3.47 → 3.51 | 6.00 → 6.02 | 0.0% → 0.0% | - | 292 → 294 | 0 → 0 | 366 → 366 | 3.0% |
| startup/full | 0.65 → 0.66 ~ | 2.99 → 3.10 ~ | 3.34 → 3.35 | 14.38 → 15.35 | 0.0% → 0.0% | 46.60 → 46.64 | 302 → 303 | 9 → 8 | 390 → 390 | 4.1% |
| switch/full | 0.65 → 0.63 ~ | 3.09 → 3.08 ~ | 3.19 → 3.18 | 4.87 → 4.85 | 0.0% → 0.0% | 14.48 → 14.52 | 305 → 307 | 4 → 4 | 366 → 366 | 8.4% |
| history/full | 5.51 → 5.58 ~ | 3.00 → 2.89 ~ | 3.56 → 3.56 | 7.44 → 8.38 | 0.0% → 0.0% | 16.58 → 14.02 | 305 → 305 | 0 → -1 | 371 → 371 | 10.6% |
| indicators/full | 0.65 → 0.65 ~ | 3.06 → 3.27 | 3.40 → 3.37 | 5.64 → 5.85 | 0.0% → 0.0% | 13.65 → 13.79 | 303 → 304 | -1 → -0 | 366 → 366 | 6.5% |
| memory/full | 5.68 → 5.84 ~ | 2.92 → 3.10 | 3.49 → 3.64 | 7.24 → 7.33 | 0.0% → 0.0% | - | 312 → 313 | 8 → 9 | 371 → 371 | 5.9% |
| draw/base | 4.60 → 4.65 ~ | 2.59 → 2.68 | 3.03 → 3.27 | 6.04 → 6.13 | 0.0% → 0.0% | - | 313 → 314 | -2 → -2 | 371 → 370 | 2.9% |

Each cell is `baseline → target`; `frames` is frames per window, `!` marks a difference above 10% (the two versions drew a different amount of work).
# L3 device summary

- device: ANP-AN00 (Android_14), impeller, 60Hz, budget 16.67ms
- target: `2.7.0` (`d321be9305`), 2 runs
- baseline: `2.6.1` (`47ce52b9ad`), 2 runs
- Flutter 3.47.5, profile build; values are medians over windows, in ms
- percentiles use nearest rank, medians over an even count take the upper one; `op p50` is accurate to about one frame; `noise` is the relative spread of p90 between runs of the same version, `~` marks a difference within it; `RSS MB` is the process RSS at the end of each window and includes heap left by earlier scenarios, `ΔRSS MB` subtracts the RSS measured before the scenario mounted (no forced GC, approximate)

| scenario | build p90 | raster p90 | raster p99 | worst | over budget | op p50 | RSS MB | ΔRSS MB | frames | noise |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| pan/base | 3.73 → 3.75 ~ | 4.01 → 3.92 ~ | 4.91 → 4.74 | 8.54 → 6.48 | 0.0% → 0.0% | - | 166 → 166 | 20 → 20 | 370 → 371 | 3.7% |
| pan/full | 9.37 → 9.47 | 5.22 → 5.21 ~ | 5.93 → 6.20 | 11.41 → 13.60 | 0.0% → 0.0% | - | 175 → 175 | 9 → 8 | 371 → 372 | 0.9% |
| fling/full | 9.34 → 9.39 ~ | 5.74 → 5.40 ~ | 6.66 → 6.28 | 12.78 → 12.67 | 0.0% → 0.0% | - | 185 → 181 | 8 → 5 | 388 → 388 | 5.9% |
| scale/full | 7.14 → 7.30 ~ | 6.07 → 5.79 ~ | 8.97 → 8.71 | 11.09 → 11.09 | 0.0% → 0.0% | - | 192 → 190 | 8 → 7 | 366 → 366 | 5.8% |
| zoom/full | 6.91 → 6.99 ~ | 5.64 → 5.64 ~ | 6.27 → 6.51 | 10.77 → 9.17 | 0.0% → 0.0% | - | 199 → 194 | 3 → 2 | 366 → 366 | 1.7% |
| cross/full | 9.77 → 9.86 ~ | 5.82 → 5.82 ~ | 6.66 → 6.58 | 13.14 → 11.76 | 0.0% → 0.0% | - | 202 → 196 | 2 → 1 | 448 → 448 | 2.1% |
| resize/full | 7.42 → 7.47 ~ | 5.70 → 5.75 ~ | 6.49 → 6.34 | 19.99 → 17.65 | 0.2% → 0.2% | - | 198 → 196 | -0 → 0 | 470 → 471 | 3.7% |
| realtime/full | 6.48 → 6.52 ~ | 5.95 → 5.94 ~ | 6.93 → 6.81 | 15.79 → 10.55 | 0.0% → 0.0% | - | 200 → 197 | 1 → 1 | 364 → 368 | 1.6% |
| startup/full | 1.36 → 2.10 ~ | 5.90 → 5.90 ~ | 6.71 → 6.63 | 40.63 → 40.88 | 2.6% → 2.6% | 58.30 → 57.70 | 205 → 206 | 5 → 10 | 351 → 351 | 98.1% |
| switch/full | 2.46 → 2.49 ~ | 5.67 → 5.59 ~ | 7.39 → 6.49 | 18.40 → 14.58 | 0.3% → 0.0% | 24.84 → 26.57 | 209 → 210 | 3 → 4 | 368 → 369 | 11.4% |
| history/full | 9.06 → 9.14 ~ | 5.33 → 5.29 ~ | 6.43 → 6.37 | 12.28 → 13.48 | 0.0% → 0.0% | 14.28 → 15.59 | 209 → 210 | 1 → 0 | 371 → 372 | 2.9% |
| indicators/full | 2.71 → 2.78 ~ | 6.05 → 6.02 ~ | 6.52 → 6.86 | 16.33 → 15.62 | 0.0% → 0.0% | 30.84 → 30.52 | 210 → 209 | 1 → -1 | 369 → 369 | 6.1% |
| memory/full | 9.56 → 9.59 ~ | 5.38 → 5.35 ~ | 6.67 → 6.64 | 12.40 → 11.34 | 0.0% → 0.0% | - | 216 → 218 | 8 → 10 | 372 → 372 | 2.0% |
| draw/base | 8.20 → 8.33 ~ | 4.78 → 4.52 ~ | 5.60 → 5.13 | 10.27 → 40.71 | 0.0% → 0.3% | - | 213 → 214 | -5 → -6 | 372 → 371 | 8.2% |

Each cell is `baseline → target`; `frames` is frames per window, `!` marks a difference above 10% (the two versions drew a different amount of work).
# L3 device summary

- device: ANP-AN00 (Android_14), impeller, 120Hz, budget 8.33ms
- target: `2.7.0` (`d321be9305`), 2 runs
- baseline: `2.6.1` (`47ce52b9ad`), 2 runs
- Flutter 3.47.5, profile build; values are medians over windows, in ms
- percentiles use nearest rank, medians over an even count take the upper one; `op p50` is accurate to about one frame; `noise` is the relative spread of p90 between runs of the same version, `~` marks a difference within it; `RSS MB` is the process RSS at the end of each window and includes heap left by earlier scenarios, `ΔRSS MB` subtracts the RSS measured before the scenario mounted (no forced GC, approximate)

| scenario | build p90 | raster p90 | raster p99 | worst | over budget | op p50 | RSS MB | ΔRSS MB | frames | noise |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| pan/base | 2.57 → 2.59 ~ | 3.28 → 3.29 ~ | 4.09 → 4.04 | 6.92 → 6.57 | 0.0% → 0.0% | - | 168 → 168 | 21 → 22 | 734 → 734 | 2.9% |
| pan/full | 6.57 → 6.71 ~ | 3.86 → 3.73 | 4.75 → 4.64 | 10.62 → 11.03 | 1.3% → 2.2% | - | 178 → 177 | 10 → 8 | 685 → 678 | 2.7% |
| fling/full | 5.36 → 5.35 ~ | 3.60 → 3.50 | 4.47 → 4.33 | 9.45 → 10.04 | 0.4% → 0.3% | - | 185 → 184 | 6 → 5 | 755 → 758 | 0.3% |
| scale/full | 5.10 → 5.04 ~ | 4.21 → 4.17 ~ | 5.57 → 6.02 | 9.15 → 8.32 | 0.1% → 0.0% | - | 195 → 193 | 9 → 7 | 726 → 726 | 5.4% |
| zoom/full | 4.61 → 4.62 ~ | 4.63 → 4.45 | 5.49 → 5.31 | 9.21 → 10.01 | 0.3% → 0.1% | - | 200 → 196 | 1 → 1 | 726 → 726 | 2.9% |
| cross/full | 6.14 → 5.97 ~ | 4.54 → 4.47 ~ | 5.39 → 5.42 | 10.78 → 11.65 | 2.5% → 2.3% | - | 203 → 198 | 2 → 3 | 678 → 678 | 4.5% |
| resize/full | 4.60 → 4.68 ~ | 4.68 → 4.64 ~ | 5.33 → 5.26 | 12.60 → 10.18 | 1.6% → 0.3% | - | 203 → 197 | 0 → 0 | 941 → 941 | 2.4% |
| realtime/full | 1.71 → 2.00 | 5.00 → 4.88 ~ | 5.51 → 5.57 | 8.71 → 8.43 | 0.1% → 0.1% | - | 203 → 197 | 1 → 1 | 733 → 731 | 8.3% |
| startup/full | 1.00 → 1.01 ~ | 4.91 → 4.85 ~ | 5.35 → 5.36 | 19.72 → 19.16 | 1.3% → 1.3% | 28.45 → 27.99 | 210 → 208 | 8 → 10 | 752 → 752 | 5.2% |
| switch/full | 1.10 → 1.16 ~ | 4.61 → 4.55 ~ | 5.22 → 5.26 | 6.75 → 7.27 | 0.0% → 0.0% | 12.41 → 14.12 | 215 → 214 | 5 → 6 | 731 → 730 | 7.6% |
| history/full | 5.94 → 5.89 ~ | 3.75 → 3.75 ~ | 4.67 → 4.55 | 12.95 → 12.56 | 1.0% → 0.9% | 8.29 → 7.70 | 213 → 212 | -2 → -0 | 695 → 701 | 2.8% |
| indicators/full | 1.09 → 1.11 ~ | 4.88 → 4.84 ~ | 5.45 → 5.34 | 7.55 → 8.10 | 0.0% → 0.0% | 13.33 → 13.41 | 212 → 211 | -1 → -1 | 732 → 732 | 6.2% |
| memory/full | 6.14 → 6.41 | 3.76 → 3.82 ~ | 4.77 → 4.71 | 11.88 → 10.61 | 1.0% → 1.7% | - | 220 → 220 | 8 → 9 | 695 → 691 | 2.0% |
| draw/base | 6.32 → 6.36 ~ | 3.34 → 3.36 ~ | 4.18 → 4.11 | 32.15 → 32.00 | 1.7% → 2.0% | - | 224 → 225 | 3 → 3 | 677 → 671 | 16.6% |

Each cell is `baseline → target`; `frames` is frames per window, `!` marks a difference above 10% (the two versions drew a different amount of work).

# L3 device summary

- device: iPhone_16 (iOS_26.6.1_23G83), impeller, 60Hz, budget 16.67ms
- target: `2.6.1` (`8a0c362dcb`), 2 runs
- baseline: `2.5.6` (`3eb8b96a97`), 2 runs
- Flutter 3.47.5, profile build; values are medians over windows, in ms
- percentiles use nearest rank, medians over an even count take the upper one; `op p50` is accurate to about one frame; `noise` is the relative spread of p90 between runs of the same version, `~` marks a difference within it; `RSS MB` is the process RSS at the end of each window and includes heap left by earlier scenarios, `ΔRSS MB` subtracts the RSS measured before the scenario mounted (no forced GC, approximate)

| scenario | build p90 | raster p90 | raster p99 | worst | over budget | op p50 | RSS MB | ΔRSS MB | frames | noise |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| pan/base | 2.87 → 1.61 | 0.97 → 0.97 ~ | 1.05 → 1.07 | 3.24 → 1.96 | 0.0% → 0.0% | - | 86 → 88 | 4 → 15 | 371 → 371 | 5.5% |
| pan/full | 5.11 → 4.47 | 1.21 → 1.26 | 1.37 → 1.41 | 6.31 → 5.45 | 0.0% → 0.0% | - | 94 → 97 | 6 → 7 | 370 → 370 | 3.3% |
| fling/full | 4.54 → 4.11 | 1.08 → 1.20 | 1.20 → 1.30 | 5.53 → 4.91 | 0.0% → 0.0% | - | 99 → 98 | 5 → 3 | 384 → 384 | 2.7% |
| scale/full | 4.72 → 3.62 | 2.06 → 2.13 ~ | 2.88 → 2.95 | 6.68 → 5.16 | 0.0% → 0.0% | - | 103 → 104 | 6 → 5 | 366 → 366 | 4.0% |
| zoom/full | 4.38 → 3.45 | 1.31 → 1.56 | 1.68 → 1.68 | 5.89 → 4.00 | 0.0% → 0.0% | - | 104 → 105 | 4 → 2 | 366 → 366 | 2.7% |
| cross/full | 4.55 → 4.64 ~ | 1.43 → 1.50 | 1.74 → 1.76 | 5.86 → 5.95 | 0.0% → 0.0% | - | 111 → 110 | 4 → 4 | 472 → 472 | 4.6% |
| resize/full | 4.17 → 3.45 | 1.62 → 1.56 ~ | 1.70 → 1.66 | 5.51 → 4.29 | 0.0% → 0.0% | - | 112 → 114 | 3 → 3 | 471 → 471 | 5.0% |
| realtime/full | 4.25 → 3.06 | 1.66 → 1.62 ~ | 1.75 → 1.72 | 6.05 → 4.78 | 0.0% → 0.0% | - | 109 → 114 | 0 → 2 | 362 → 363 | 3.9% |
| startup/full | 0.55 → 0.57 | 1.65 → 1.60 ~ | 1.73 → 1.72 | 10.58 → 11.10 | 0.0% → 0.0% | 30.20 → 30.49 | 108 → 119 | 4 → 5 | 390 → 390 | 4.5% |
| switch/full | 0.57 → 0.58 ~ | 1.48 → 1.42 | 1.55 → 1.55 | 5.17 → 3.63 | 0.0% → 0.0% | 13.66 → 13.40 | 118 → 123 | -1 → 2 | 366 → 366 | 3.2% |
| history/full | 4.85 → 4.37 | 1.17 → 1.24 ~ | 1.33 → 1.38 | 6.24 → 5.44 | 0.0% → 0.0% | 14.87 → 15.84 | 112 → 122 | -2 → -3 | 370 → 370 | 6.4% |
| indicators/full | 0.62 → 0.59 ~ | 1.62 → 1.63 ~ | 1.84 → 1.73 | 5.46 → 4.69 | 0.0% → 0.0% | 14.20 → 14.61 | 98 → 119 | -2 → -7 | 366 → 366 | 15.5% |
| memory/full | 5.05 → 4.53 | 1.19 → 1.25 ~ | 1.36 → 1.36 | 6.31 → 5.25 | 0.0% → 0.0% | - | 107 → 134 | 19 → 14 | 370 → 369 | 7.4% |
| draw/base | 7.44 → 3.65 | 1.04 → 1.06 ~ | 1.34 → 1.24 | 8.65 → 4.50 | 0.0% → 0.0% | - | 113 → 130 | 3 → 2 | 369 → 370 | 38.8% |

Each cell is `baseline → target`; `frames` is frames per window, `!` marks a difference above 10% (the two versions drew a different amount of work).
# L3 device summary

- device: PLZ110 (Android_17), impeller, 60Hz, budget 16.67ms
- target: `2.6.1` (`8a0c362dcb`), 2 runs
- baseline: `2.5.6` (`3eb8b96a97`), 2 runs
- Flutter 3.47.5, profile build; values are medians over windows, in ms
- percentiles use nearest rank, medians over an even count take the upper one; `op p50` is accurate to about one frame; `noise` is the relative spread of p90 between runs of the same version, `~` marks a difference within it; `RSS MB` is the process RSS at the end of each window and includes heap left by earlier scenarios, `ΔRSS MB` subtracts the RSS measured before the scenario mounted (no forced GC, approximate)

| scenario | build p90 | raster p90 | raster p99 | worst | over budget | op p50 | RSS MB | ΔRSS MB | frames | noise |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| pan/base | 3.30 → 1.96 | 2.48 → 2.38 ~ | 2.58 → 2.50 | 4.05 → 2.77 | 0.0% → 0.0% | - | 281 → 280 | 19 → 18 | 371 → 370 | 19.1% |
| pan/full | 7.23 → 6.13 | 2.31 → 2.88 | 3.36 → 3.41 | 8.78 → 7.51 | 0.0% → 0.0% | - | 290 → 288 | 9 → 8 | 370 → 372 | 7.0% |
| fling/full | 7.15 → 5.69 | 2.18 → 2.19 ~ | 2.97 → 3.01 | 8.63 → 7.83 | 0.0% → 0.0% | - | 295 → 293 | 4 → 3 | 387 → 386 | 0.9% |
| scale/full | 6.92 → 4.53 | 3.19 → 3.20 ~ | 5.01 → 5.11 | 9.53 → 7.94 | 0.0% → 0.0% | - | 306 → 302 | 10 → 9 | 366 → 366 | 4.9% |
| zoom/full | 6.42 → 3.99 | 2.36 → 3.04 | 3.29 → 3.40 | 7.58 → 5.04 | 0.0% → 0.0% | - | 310 → 305 | 3 → 2 | 366 → 366 | 2.5% |
| cross/full | 6.11 → 5.83 | 2.46 → 3.37 | 3.39 → 3.83 | 7.49 → 7.03 | 0.0% → 0.0% | - | 312 → 309 | 0 → 3 | 366 → 366 | 2.6% |
| resize/full | 6.64 → 4.45 | 2.85 → 2.97 ~ | 3.30 → 3.36 | 8.25 → 6.50 | 0.0% → 0.0% | - | 312 → 312 | 0 → 2 | 471 → 471 | 15.5% |
| realtime/full | 5.82 → 3.96 | 3.21 → 3.27 ~ | 3.47 → 3.48 | 7.98 → 6.55 | 0.0% → 0.0% | - | 311 → 313 | -0 → 1 | 366 → 366 | 2.9% |
| startup/full | 0.66 → 0.67 ~ | 3.10 → 3.13 ~ | 3.31 → 3.33 | 15.28 → 15.17 | 0.0% → 0.0% | 46.92 → 46.95 | 321 → 321 | 10 → 10 | 390 → 390 | 3.1% |
| switch/full | 0.62 → 0.75 | 2.99 → 2.99 ~ | 3.09 → 3.10 | 6.77 → 4.74 | 0.0% → 0.0% | 19.96 → 14.55 | 325 → 326 | 4 → 5 | 369 → 366 | 3.1% |
| history/full | 6.90 → 5.48 | 2.45 → 2.86 ~ | 3.43 → 3.52 | 8.79 → 8.31 | 0.0% → 0.0% | 16.84 → 16.31 | 325 → 324 | -0 → -1 | 371 → 371 | 17.1% |
| indicators/full | 0.66 → 0.68 ~ | 3.18 → 3.18 ~ | 3.30 → 3.35 | 7.35 → 5.76 | 0.0% → 0.0% | 13.28 → 13.76 | 323 → 325 | -2 → 1 | 366 → 366 | 14.6% |
| memory/full | 7.22 → 5.73 | 2.45 → 3.04 | 3.50 → 3.58 | 9.36 → 7.45 | 0.0% → 0.0% | - | 332 → 331 | 9 → 7 | 369 → 371 | 0.7% |
| draw/base | 13.07 → 4.69 | 2.23 → 2.53 | 2.85 → 3.13 | 17.16 → 6.26 | 0.3% → 0.0% | - | 333 → 331 | 1 → 1 | 372 → 370 | 7.8% |

Each cell is `baseline → target`; `frames` is frames per window, `!` marks a difference above 10% (the two versions drew a different amount of work).
# L3 device summary

- device: ANP-AN00 (Android_14), impeller, 60Hz, budget 16.67ms
- target: `2.6.1` (`8a0c362dcb`), 2 runs
- baseline: `2.5.6` (`3eb8b96a97`), 2 runs
- Flutter 3.47.5, profile build; values are medians over windows, in ms
- percentiles use nearest rank, medians over an even count take the upper one; `op p50` is accurate to about one frame; `noise` is the relative spread of p90 between runs of the same version, `~` marks a difference within it; `RSS MB` is the process RSS at the end of each window and includes heap left by earlier scenarios, `ΔRSS MB` subtracts the RSS measured before the scenario mounted (no forced GC, approximate)

| scenario | build p90 | raster p90 | raster p99 | worst | over budget | op p50 | RSS MB | ΔRSS MB | frames | noise |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| pan/base | 6.96 → 4.25 | 4.62 → 4.30 ~ | 6.33 → 5.33 | 10.19 → 8.58 | 0.0% → 0.0% | - | 163 → 161 | 21 → 19 | 371 → 372 | 28.9% |
| pan/full | 11.26 → 9.65 | 4.73 → 5.17 | 5.75 → 6.35 | 13.20 → 13.87 | 0.0% → 0.0% | - | 174 → 169 | 9 → 8 | 373 → 373 | 3.9% |
| fling/full | 10.78 → 9.52 ~ | 5.54 → 5.93 ~ | 6.38 → 6.61 | 15.75 → 11.54 | 0.0% → 0.0% | - | 183 → 175 | 8 → 4 | 388 → 388 | 14.6% |
| scale/full | 9.60 → 7.52 | 5.16 → 5.80 | 7.87 → 8.58 | 13.59 → 11.25 | 0.0% → 0.0% | - | 190 → 183 | 8 → 8 | 366 → 366 | 6.3% |
| zoom/full | 9.84 → 6.88 | 5.36 → 5.62 | 6.41 → 6.08 | 13.28 → 9.29 | 0.0% → 0.0% | - | 196 → 189 | 2 → 3 | 366 → 366 | 2.0% |
| cross/full | 10.13 → 9.79 | 5.82 → 5.84 ~ | 6.58 → 6.71 | 12.39 → 12.43 | 0.0% → 0.0% | - | 195 → 191 | 1 → 3 | 448 → 448 | 2.4% |
| resize/full | 9.95 → 7.32 | 5.56 → 5.65 ~ | 6.79 → 6.43 | 24.35 → 20.21 | 0.2% → 0.2% | - | 196 → 191 | 1 → 0 | 471 → 471 | 2.5% |
| realtime/full | 10.27 → 6.54 | 6.34 → 5.83 ~ | 7.26 → 6.67 | 12.91 → 20.12 | 0.0% → 0.5% | - | 195 → 192 | 0 → 1 | 363 → 364 | 12.9% |
| startup/full | 2.18 → 1.31 ~ | 6.08 → 5.61 ~ | 6.87 → 6.46 | 40.00 → 40.61 | 2.6% → 2.6% | 58.20 → 58.03 | 201 → 201 | 9 → 9 | 352 → 351 | 77.4% |
| switch/full | 2.50 → 2.47 ~ | 5.92 → 5.47 | 6.74 → 6.57 | 12.66 → 10.53 | 0.0% → 0.0% | 27.73 → 30.89 | 205 → 206 | 4 → 4 | 371 → 367 | 7.3% |
| history/full | 10.79 → 9.03 | 4.92 → 5.29 | 6.21 → 6.42 | 16.74 → 11.38 | 0.3% → 0.0% | 15.09 → 14.99 | 204 → 205 | -0 → -1 | 371 → 373 | 2.0% |
| indicators/full | 2.64 → 2.59 ~ | 6.08 → 5.92 ~ | 6.94 → 6.54 | 23.37 → 17.09 | 1.1% → 0.3% | 32.32 → 30.30 | 205 → 205 | 1 → -0 | 369 → 368 | 6.3% |
| memory/full | 11.27 → 9.50 | 4.97 → 5.40 | 6.59 → 5.94 | 15.38 → 12.13 | 0.0% → 0.0% | - | 213 → 213 | 8 → 8 | 372 → 372 | 3.0% |
| draw/base | 21.61 → 8.28 | 4.09 → 4.52 ~ | 5.75 → 5.45 | 34.77 → 10.81 | 43.7% → 0.0% | - | 213 → 212 | -0 → -1 | 260 → 372 ! | 12.1% |

Each cell is `baseline → target`; `frames` is frames per window, `!` marks a difference above 10% (the two versions drew a different amount of work).
# L3 device summary

- device: ANP-AN00 (Android_14), impeller, 120Hz, budget 8.33ms
- target: `2.6.1` (`8a0c362dcb`), 2 runs
- baseline: `2.5.6` (`3eb8b96a97`), 2 runs
- Flutter 3.47.5, profile build; values are medians over windows, in ms
- percentiles use nearest rank, medians over an even count take the upper one; `op p50` is accurate to about one frame; `noise` is the relative spread of p90 between runs of the same version, `~` marks a difference within it; `RSS MB` is the process RSS at the end of each window and includes heap left by earlier scenarios, `ΔRSS MB` subtracts the RSS measured before the scenario mounted (no forced GC, approximate)

| scenario | build p90 | raster p90 | raster p99 | worst | over budget | op p50 | RSS MB | ΔRSS MB | frames | noise |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| pan/base | 4.75 → 2.64 | 3.08 → 3.26 | 3.94 → 3.97 | 9.86 → 6.32 | 0.1% → 0.0% | - | 164 → 163 | 22 → 20 | 724 → 734 | 1.2% |
| pan/full | 8.93 → 6.50 | 4.03 → 3.78 ~ | 4.82 → 4.69 | 12.98 → 10.24 | 14.6% → 1.7% | - | 174 → 173 | 8 → 9 | 611 → 688 ! | 6.6% |
| fling/full | 6.52 → 5.40 | 3.23 → 3.53 | 4.25 → 4.37 | 12.29 → 9.36 | 2.7% → 0.4% | - | 181 → 181 | 5 → 6 | 740 → 756 | 5.6% |
| scale/full | 7.71 → 5.05 | 3.84 → 4.19 | 5.78 → 5.66 | 11.76 → 10.13 | 5.2% → 0.1% | - | 188 → 190 | 6 → 7 | 726 → 726 | 2.7% |
| zoom/full | 6.94 → 4.63 | 4.30 → 4.55 ~ | 5.17 → 5.42 | 11.84 → 8.07 | 3.9% → 0.0% | - | 190 → 193 | 1 → 1 | 726 → 726 | 13.3% |
| cross/full | 6.20 → 6.21 ~ | 4.09 → 4.43 ~ | 4.99 → 5.39 | 10.40 → 10.55 | 1.5% → 2.5% | - | 192 → 196 | 1 → 1 | 904 → 678 ! | 30.0% |
| resize/full | 5.21 → 4.61 ~ | 4.57 → 4.73 ~ | 5.07 → 5.25 | 11.98 → 10.56 | 0.3% → 0.2% | - | 193 → 196 | 1 → 0 | 939 → 940 | 26.1% |
| realtime/full | 2.95 → 1.70 ~ | 4.88 → 4.93 ~ | 5.43 → 5.67 | 14.55 → 10.54 | 2.2% → 0.1% | - | 193 → 196 | 1 → 1 | 707 → 730 | 43.5% |
| startup/full | 1.02 → 1.03 | 4.84 → 4.86 ~ | 5.31 → 5.35 | 19.66 → 18.89 | 1.3% → 1.3% | 27.67 → 27.88 | 203 → 205 | 11 → 9 | 749 → 752 | 1.0% |
| switch/full | 1.13 → 1.13 ~ | 4.53 → 4.54 ~ | 5.38 → 5.40 | 9.34 → 9.12 | 0.3% → 0.1% | 14.17 → 13.06 | 208 → 209 | 4 → 4 | 729 → 730 | 2.8% |
| history/full | 7.87 → 5.92 | 3.64 → 3.78 ~ | 4.60 → 4.61 | 16.86 → 12.64 | 8.5% → 1.0% | 11.67 → 10.26 | 208 → 208 | -0 → -0 | 646 → 701 | 5.3% |
| indicators/full | 1.11 → 1.14 | 4.85 → 4.85 ~ | 5.27 → 5.34 | 10.15 → 8.33 | 0.3% → 0.0% | 15.26 → 13.61 | 207 → 208 | -0 → -0 | 731 → 731 | 2.5% |
| memory/full | 8.20 → 5.92 | 3.72 → 3.73 ~ | 4.64 → 4.73 | 16.90 → 10.74 | 9.5% → 0.9% | - | 215 → 216 | 9 → 9 | 641 → 712 ! | 24.0% |
| draw/base | 15.75 → 5.99 | 3.02 → 3.31 ~ | 3.86 → 4.18 | 29.14 → 31.68 | 77.6% → 1.6% | - | 213 → 222 | -3 → 6 | 381 → 689 ! | 25.1% |

Each cell is `baseline → target`; `frames` is frames per window, `!` marks a difference above 10% (the two versions drew a different amount of work).

# FlexiKline device benchmark

On-device frame benchmark (L3) for `flexi_kline`: drives the chart with real gestures and data operations in a profile build and records raw build / raster frame times, per-operation latency and RSS. It is not published and is not an example of how to use the library.

## Quick start

```bash
# 1. iOS only, once: signing team in ios/Flutter/Local.xcconfig (git-ignored)
#      DEVELOPMENT_TEAM = ABCDE12345
#      CODE_SIGN_STYLE = Automatic
# 2. find the device id
fvm flutter devices
# 3. smoke: one quick scenario to check the device link (from the repository root)
tool/benchmark/device.sh --device <id> --hz 60 --scenario pan/base --windows 1 --window-seconds 3 --allow-dirty
```

`--scenario` picks what to run: names are `<action>/<preset>` (`pan/base` = drag back and forth on a candles-only chart). The smoke run above uses `pan/base` just to confirm the device builds, signs, connects and reports its refresh rate. Drop `--scenario` to run **all 20 scenarios** (adds a few minutes, checks every scenario's precondition on this device); use `'pan/*'` for a prefix match. A run ends with `wrote build/benchmark/device/... (refresh rate 60.0Hz)`. For the full multi-device capture use `tool/benchmark/matrix.sh` (see `tool/README.md`).

Try the chart by hand: `fvm flutter run --profile -d <id> --dart-define=PRESET=full`, then watch frames in DevTools.

## Layout

| path | what it is |
| --- | --- |
| `lib/src/app.dart`, `chart.dart` | `BenchApp` / `BenchChart`; `BenchChartState.controller` and `subKeys` are the test hooks |
| `lib/src/preset.dart` | `BenchPreset { base, full }` (which indicators) and `BenchFeature { draw, resize, zoom }` (opt-in interactions) |
| `lib/src/config/` | non-persisting `BenchConfiguration` (activates the preset's indicators, turns features on) and a fixed theme |
| `lib/src/data/candles.dart` | fixed-seed candles and realtime ticks |
| `lib/src/indicators/` | VOL, MA, MACD, VOLMA: minimal configuration, calculation and painting ported from `flexi_kline_indicators` |
| `integration_test/bench_test.dart` | device-side entry: mounts each scenario, warms up, records windows, reports raw data |
| `integration_test/src/` | `ScenarioContext`, recorder, gesture primitives, scenario tables, `compat.dart` / `compat_baseline.dart` |
| `test_driver/bench_driver.dart` | host side: checks the refresh rate, writes `frames.json` / trace summary |
| `test/` | indicator calculation and preset activation tests (`fvm flutter test`) |

## Scenarios

Names are `<action>/<preset>`; existing names never change so results stay comparable across versions. Presets: `base` (candles and time axis), `full` (main VOL + MA, sub MACD + VOLMA). Input is emitted at the measured refresh rate, so high-refresh devices get an event every vsync.

| action | what it does | presets |
| --- | --- | --- |
| `pan` / `fling` | drag back and forth / fling and wait for inertia | `base`, `full` |
| `scale` | two-finger pinch (candle width) | `base`, `full` |
| `zoom` | vertical drag on the price axis (Y range), feature `zoom` | `base`, `full` |
| `cross` | crosshair sweep | `base`, `full` |
| `resize` | drag the main / sub divider through the controller API (touch has no divider gesture), feature `resize` | `full` |
| `realtime` | a tick every 100 ms, view still | `base`, `full` |
| `startup` | unmount and mount a fresh chart; op = mount to first painted frame | `base`, `full` |
| `switch` | switch between two symbols (2000 / 5000 candles); op = call until the data pipeline is idle | `full` |
| `history` | append 500 older candles mid-drag; op = the append call until the pipeline is idle and the next frame is painted | `full` |
| `indicators` | show / hide the sub indicators; op = toggle until the pipeline is idle | `full` |
| `draw` | 30 drawings + `pan`, feature `draw` | `base` |
| `memory` | 20000 candles + `pan`; watch RSS | `full` |

`SCENARIO` takes a comma list and `/*` prefixes, e.g. `pan/*,zoom/full`. Every scenario asserts that its action took effect (offset changed, candle width changed, zoom entered...), so a gesture that silently misses fails instead of producing fast, empty frames.

## Rules for changes

- Only use API that also exists in the baseline (`v2.5.6-monorepo`); put a version difference in `integration_test/src/compat.dart` and its baseline twin `compat_baseline.dart`, same signatures.
- New scenarios are appended; never rename an existing one.
- After a change: `fvm flutter analyze`, `fvm flutter test`, then `fvm flutter test -d flutter-tester integration_test/bench_test.dart --dart-define=WINDOWS=1 --dart-define=WINDOW_SECONDS=2` here and in the baseline tree (`tool/benchmark/overlay.sh build/benchmark/wt/<sha> --app`).

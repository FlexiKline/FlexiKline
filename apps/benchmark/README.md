# FlexiKline device benchmark

On-device frame benchmark (L3) for `flexi_kline`: drives the chart with real gestures and data operations in a profile build and records raw build / raster frame times, per-operation latency and RSS. It is not published and is not an example of how to use the library.

## Scenarios

Names are `<drive>/<setup>`; existing names never change so results stay comparable across versions.

| drive | what it does | setups |
| --- | --- | --- |
| `pan` / `fling` / `zoom` / `cross` | gestures: drag back and forth, fling, pinch, crosshair sweep | `base`, `multi` |
| `realtime` | a tick every 100 ms, view still | `base`, `multi` |
| `startup` | unmount and mount a fresh chart; op = mount to first painted frame | `base`, `multi` |
| `switch` | switch between two symbols, replacing 2000 / 5000 candles; op = call to next frame | `calc` |
| `history` | append 500 older candles in the middle of a drag; op = the append call | `calc` |
| `indicators` | add / remove 4 computed sub indicators; op = change to next frame | `calc` |
| `draw` | 30 drawings (trend line, ray, rectangle, Fibonacci) + `pan` | `base` |
| `memory` | 20000 candles + `pan`; watch RSS | `calc` |

Setups: `base` candles and time axis only; `multi` adds 3 main + 4 sub draw-only lines (same as L1); `calc` the same layout with computed moving averages.

## Setup

- iOS: create `ios/Flutter/Local.xcconfig` (git-ignored) with your signing team:

  ```
  DEVELOPMENT_TEAM = ABCDE12345
  CODE_SIGN_STYLE = Automatic
  ```

- Android: enable USB debugging and pin the display refresh rate you want to measure.

## Run

All devices, both versions, one command (copy `tool/devices.example.conf` to `tool/devices.conf` first):

```bash
apps/benchmark/tool/matrix.sh                                   # v2.5.6-monorepo vs HEAD
apps/benchmark/tool/matrix.sh --baseline-ref flexi_kline-v2.6.0 # previous release vs HEAD
```

One run on one device:

```bash
apps/benchmark/tool/device.sh --device <id> --version current --hz 60 --label iphone16
apps/benchmark/tool/device.sh --device <id> --version baseline --hz 60 --label iphone16

# Android Skia backend, 120Hz
apps/benchmark/tool/device.sh --device <id> --version current --backend skia --hz 120

# timeline (and GC count) for one scenario, for DevTools
apps/benchmark/tool/device.sh --device <id> --version current --hz 60 --mode trace --scenario pan/multi

# merge runs of one device / backend / refresh rate
fvm dart run tool/benchmark/summarize.dart l3 \
  --target build/benchmark/device/<session>/<combo>/current \
  --baseline build/benchmark/device/<session>/<combo>/baseline \
  --out build/benchmark/device/<session>/<combo>
```

Both scripts refuse to run on a dirty working tree (results record the commit they measured); `--allow-dirty` is for smoke runs only. A quick smoke run: `--scenario pan/base --windows 1 --window-seconds 3`.

Manual check with DevTools: `fvm flutter run --profile -d <id> --dart-define=SETUP=calc`.

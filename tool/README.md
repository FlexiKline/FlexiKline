# tool

Repository-level scripts. Everything here runs from the repository root with `fvm`.

| path | what it is |
| --- | --- |
| `benchmark/` | performance benchmarks: L1 host micro benchmarks and version compare, L3 on-device frame capture |
| `analysis_options.yaml` | formatter only (120 columns, `trailing_commas: preserve`), so CLI and IDE format `tool/` the same way as the packages |

## benchmark

| script | use it to |
| --- | --- |
| `compare.sh` | compare L1 frame benchmarks of two versions on this machine |
| `device.sh` | run one on-device capture on one device |
| `matrix.sh` | run a full capture on every device in `devices.conf`, both versions |
| `build.sh` | build a profile benchmark app once for `device.sh --binary` (matrix calls it) |
| `overlay.sh` | copy the current benchmark code into another version's worktree (called by the others) |
| `lib.sh` | shared shell functions (sourced, not run) |
| `bench.dart` | data processing: `summarize micro|device`, `plan`, `device-info`, `flutter-version`, `env` |
| `devices.example.conf` | template for the git-ignored `devices.conf` |

```bash
# L1: this machine, v2.5.6-monorepo vs HEAD (needs a clean working tree; add --allow-dirty to try it out)
tool/benchmark/compare.sh --baseline v2.5.6-monorepo

# L3: one device, smoke run — pan/base just checks the device link (drop --scenario to run all 20, or use 'pan/*')
tool/benchmark/device.sh --device <id> --hz 60 --scenario pan/base --windows 1 --window-seconds 3 --allow-dirty

# L3: all devices, both versions
cp tool/benchmark/devices.example.conf tool/benchmark/devices.conf   # then fill in device ids
tool/benchmark/matrix.sh

# merge existing runs again
fvm dart tool/benchmark/bench.dart summarize device --target <dir>/target --baseline <dir>/baseline --out <dir>
```

Results go to `build/benchmark/` (ignored). Baseline worktrees are cached under `build/benchmark/wt/<sha>`; remove one with `git worktree remove --force build/benchmark/wt/<sha>`.

The device app and its scenarios live in `apps/benchmark/` (see its README).

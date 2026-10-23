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
| `matrix.sh` | run an unattended capture on the devices in `devices.conf`, both versions, one refresh rate per call (`--hz`); writes `retry-<time>.sh` for failed runs |
| `build.sh` | build a profile benchmark app once for `device.sh --binary` (matrix calls it) |
| `overlay.sh` | copy the current benchmark code into another version's worktree (called by the others) |
| `publish.sh` | copy a session's `device.json` files and merged `summary.md` to `docs/benchmark/results/<session>/` (`matrix.sh --publish` calls it) |
| `clean.sh` | remove the baseline / target worktrees under `.worktrees/benchmark/` |
| `lib.sh` | shared shell functions (sourced, not run) |
| `bench.dart` | data processing: `summarize micro|device`, `plan`, `device-info`, `flutter-version`, `env` |
| `devices.example.conf` | template for the git-ignored `devices.conf` |

```bash
# L1: this machine, v2.5.6-monorepo vs HEAD (needs a clean working tree; add --allow-dirty to try it out)
tool/benchmark/compare.sh --baseline v2.5.6-monorepo

# L3: one device, smoke run — pan/base just checks the device link (drop --scenario to run all 14, or use 'pan/*')
tool/benchmark/device.sh --device <id> --hz 60 --scenario pan/base --windows 1 --window-seconds 3 --allow-dirty

# L3: all devices, both versions, one refresh rate per call (set the phones first; same --session merges)
cp tool/benchmark/devices.example.conf tool/benchmark/devices.conf   # then fill in device ids
tool/benchmark/matrix.sh --session <name> --hz 60
tool/benchmark/matrix.sh --session <name> --hz 120                   # after switching the high-refresh devices

# merge existing runs again
fvm dart tool/benchmark/bench.dart summarize device --target <dir>/target --baseline <dir>/baseline --out <dir>
```

Results go to `build/benchmark/` (ignored). The baseline worktree lives in `.worktrees/benchmark/baseline` (plus `target` when `compare.sh --target` is not HEAD): fixed names, reused while their HEAD matches the requested ref and recreated otherwise, and outside `build/` so `flutter clean` does not remove them. `tool/benchmark/clean.sh` removes them.

The device app and its scenarios live in `apps/benchmark/` (see its README).

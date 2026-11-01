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
# L1: this machine, 2.6.1 (bridge branch) vs HEAD (needs a clean working tree; add --allow-dirty to try it out)
tool/benchmark/compare.sh --baseline bench/bridge-v2.6.1

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

### Baselines and benchmark code

2.7.0 stores candles in ascending order, so the current benchmark code does not compile against 2.6.x. The default baseline of `matrix.sh`, `device.sh` and `build.sh` is therefore the local branch `bench/bridge-v2.6.1`: the `flexi_kline-v2.6.1` tag plus one commit that makes the benchmark app report `scenarioVersion` and `dataDigest` (library code identical to the tag). A baseline named `bench/bridge-*` runs **its own** benchmark code (`--own-code` is added automatically); any other baseline gets the current benchmark code copied over it, as before.

- Why not overlay: the 2.7.0 benchmark code does not compile on 2.6.1, and a compat shim would be worse, because 2.6.1 treats `list[0]` as the latest candle and would silently run a different workload. Each side therefore runs its own code, and `dataDigest` proves both fed the same candles.
- Any baseline before 2.7.0 needs a bridge branch: overlaying fails to compile, and `--own-code` on a plain tag has no `dataDigest`, so the summary reports `not comparable`. `v2.5.6-monorepo` has no `apps/benchmark` at all and can no longer be compared against. Baselines with the same data direction (2.7.0 and later tags) use `--baseline <ref>` and the overlay.
- The hand-written MA, MACD, VOL_MA and VOLUME indicators in the benchmark app differ between the two sides (descending vs ascending implementation), so `indicators/*` readings include that difference.
- `summarize device` checks that both sides ran the same workload by comparing `scenarioVersion` and each scenario's `dataDigest`, and writes a `not comparable` warning otherwise. Read that line before reading the numbers.
- The bridge branch is local, a fresh clone does not have it. Recreate it with `git branch bench/bridge-v2.6.1 flexi_kline-v2.6.1` and cherry-pick the commit that adds `apps/benchmark/lib/src/data/digest.dart` (the scripts stop with this hint when it is missing). Push it before tagging a release: `benchmark.yml` uses `origin/bench/bridge-<version>` for the L1 comparison when it exists.
- `--own-code` can also be passed by hand to `build.sh`, `device.sh`, `matrix.sh` and `compare.sh`, for a bridge branch with another name.

The device app and its scenarios live in `apps/benchmark/` (see its README).

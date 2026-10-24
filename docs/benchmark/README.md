# Benchmark results

On-device results of `flexi_kline`, captured with [apps/benchmark](../../apps/benchmark/README.md) and the scripts in [tool/](../../tool/README.md). Each session runs the baseline and the target alternately on the same devices, so read a result as "baseline → target" within that session, not as an absolute number across sessions. Each `summary.md` explains its own columns. Per-release host trend data: [benchmark-data](https://github.com/FlexiKline/benchmark-data).

## Limits

- Two runs per version per device; `noise` in the summary is the spread between them, and differences inside it are marked `~`.
- Synthetic gestures at a fixed speed: indicator calculation, network and custom indicators of a real app are not included.
- Versions from 2.6.1 emit `Flexi-*` timeline events in profile mode, older baselines do not; the cost is small but not measured separately.
- Only Impeller. 120Hz data comes from devices that stay at 120Hz without touch; some Android skins raise the refresh rate only on real touches.

## Results

| Date | Baseline → target | Devices | Summary |
| --- | --- | --- | --- |
| 2026-10-24 | `v2.5.6-monorepo` → 2.6.1 | iPhone 16 60Hz, OnePlus 15T 60Hz, Honor 80 Pro 60/120Hz | [summary.md](results/20261024-v2.5.6/summary.md) |

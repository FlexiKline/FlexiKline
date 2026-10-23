#!/usr/bin/env bash
# 把一次采集的结果发布到 docs/benchmark/results/<session>/: 每个组合的 device.json 和合并后的 summary.md。
#
#   tool/benchmark/publish.sh <session>
#
# 各组合的 device-summary.md 已经包含在 summary.md 里, 不重复发布。matrix.sh --publish 结束时调用;
# 补采后或没加 --publish 时单独执行。不删除 docs 里已有的文件。
set -euo pipefail
source "$(dirname "$0")/lib.sh"

SESSION="${1:?usage: publish.sh <session>}"
SRC="$BENCH_ROOT/build/benchmark/device/$SESSION"
DOCS="$BENCH_ROOT/docs/benchmark/results/$SESSION"
[[ -f "$SRC/summary.md" ]] || bench_die "no $SRC/summary.md; run matrix.sh first"

for combo in "$SRC"/*/; do
  [[ -f "$combo/device.json" ]] || continue
  mkdir -p "$DOCS/$(basename "$combo")"
  cp "$combo/device.json" "$DOCS/$(basename "$combo")/"
done
cp "$SRC/summary.md" "$DOCS/"
echo "published to docs/benchmark/results/$SESSION" >&2

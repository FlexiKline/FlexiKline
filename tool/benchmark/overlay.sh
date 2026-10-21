#!/usr/bin/env bash
# 把当前树的 benchmark harness 与整帧场景覆盖进另一个版本的 worktree, 只改该 worktree、不提交。
#
#   tool/benchmark/overlay.sh <worktree> [--app]
#
# --app 额外复制 apps/benchmark 并登记到根 pubspec.yaml 的 workspace(S3 起可用)。
# 被覆盖的 worktree 就是当前树时什么都不做。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WT="${1:?usage: overlay.sh <worktree> [--app]}"
WT="$(cd "$WT" && pwd)"
APP=false
[[ "${2:-}" == "--app" ]] && APP=true

[[ "$WT" == "$ROOT" ]] && exit 0

# 参与版本对照的文件; 增删时同步 compare.sh 的 FILES。
SRC="$ROOT/packages/flexi_kline/test"
DST="$WT/packages/flexi_kline/test"
FILES=(
  benchmark/bench_chart.dart
  benchmark/paint_frame_benchmark_test.dart
  benchmark/frame_scenarios_benchmark_test.dart
)

mkdir -p "$DST/support/benchmark" "$DST/benchmark"
cp "$SRC/support/benchmark/bench_harness.dart" "$DST/support/benchmark/"
for f in "${FILES[@]}"; do
  cp "$SRC/$f" "$DST/$f"
done

SUPPORT="$DST/support/support.dart"
if ! grep -q "export 'benchmark/bench_harness.dart';" "$SUPPORT"; then
  # 插在 builders/ 之前, 保持 directives_ordering(根目录 analyze 也会扫到 build/benchmark/wt/)。
  sed -i.bak "s#^export 'builders/chart_widget_scenario.dart';#export 'benchmark/bench_harness.dart';\\
export 'builders/chart_widget_scenario.dart';#" "$SUPPORT"
  rm -f "$SUPPORT.bak"
  grep -q "export 'benchmark/bench_harness.dart';" "$SUPPORT" || { echo "failed to export bench_harness in $SUPPORT" >&2; exit 1; }
fi

if $APP; then
  rm -rf "$WT/apps/benchmark"
  cp -R "$ROOT/apps/benchmark" "$WT/apps/benchmark"
  rm -rf "$WT/apps/benchmark/build" "$WT/apps/benchmark/.dart_tool"
  if ! grep -q '^  - apps/benchmark$' "$WT/pubspec.yaml"; then
    # 追加在 workspace 列表最后一项之后。
    awk '
      /^workspace:/ { in_ws = 1; print; next }
      in_ws && !/^  - / { print "  - apps/benchmark"; in_ws = 0 }
      { print }
      END { if (in_ws) print "  - apps/benchmark" }
    ' "$WT/pubspec.yaml" >"$WT/pubspec.yaml.tmp"
    mv "$WT/pubspec.yaml.tmp" "$WT/pubspec.yaml"
  fi
fi

(cd "$WT" && fvm flutter pub get >/dev/null)

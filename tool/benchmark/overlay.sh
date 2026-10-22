#!/usr/bin/env bash
# 把当前树的基准代码覆盖进另一个版本的 worktree, 只改该 worktree、不提交; 重复执行结果相同。
#
#   tool/benchmark/overlay.sh <worktree> [--app]
#
# - 总是复制: L1 harness 与 packages/flexi_kline/test/benchmark/versioned/ 整个目录(目录即版本对照的清单);
# - --app 另复制 apps/benchmark(integration_test/src/compat.dart 换成同目录的 compat_baseline.dart)
#   并登记到根 pubspec.yaml 的 workspace。
# 被覆盖的 worktree 就是当前树时什么都不做。
set -euo pipefail
source "$(dirname "$0")/lib.sh"

WT="${1:?usage: overlay.sh <worktree> [--app]}"
WT="$(cd "$WT" && pwd)"
[[ "$WT" == "$BENCH_ROOT" ]] && exit 0

SRC="$BENCH_ROOT/packages/flexi_kline/test"
DST="$WT/packages/flexi_kline/test"
# 两个版本必须用同一个 Flutter SDK 构建, 否则 SDK 的差异会混进版本差异。
cp "$BENCH_ROOT/.fvmrc" "$WT/.fvmrc"
mkdir -p "$DST/support/benchmark" "$DST/benchmark"
cp "$SRC/support/benchmark/bench_harness.dart" "$DST/support/benchmark/"
rm -rf "$DST/benchmark/versioned"
cp -R "$SRC/benchmark/versioned" "$DST/benchmark/versioned"

if [[ "${2:-}" == "--app" ]]; then
  rm -rf "$WT/apps/benchmark"
  cp -R "$BENCH_ROOT/apps/benchmark" "$WT/apps/benchmark"
  rm -rf "$WT/apps/benchmark/build" "$WT/apps/benchmark/.dart_tool"
  # 版本差异的唯一适配点, 见 integration_test/src/compat.dart。
  cp "$WT/apps/benchmark/integration_test/src/compat_baseline.dart" "$WT/apps/benchmark/integration_test/src/compat.dart"
  if ! grep -q '^  - apps/benchmark$' "$WT/pubspec.yaml"; then
    # 追加在 workspace 列表最后一项之后。
    awk '
      /^workspace:/ { in_ws = 1; print; next }
      in_ws && !/^  - / { print "  - apps/benchmark"; in_ws = 0 }
      { print }
      END { if (in_ws) print "  - apps/benchmark" }
    ' "$WT/pubspec.yaml" >"$WT/pubspec.yaml.tmp"
    mv "$WT/pubspec.yaml.tmp" "$WT/pubspec.yaml"
    grep -q '^  - apps/benchmark$' "$WT/pubspec.yaml" || { echo "failed to add apps/benchmark to $WT/pubspec.yaml" >&2; exit 1; }
  fi
fi

(cd "$WT" && fvm flutter pub get >/dev/null)

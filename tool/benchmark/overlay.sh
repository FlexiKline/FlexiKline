#!/usr/bin/env bash
# 把当前树的基准代码覆盖进另一个版本的 worktree, 只改该 worktree、不提交; 重复执行结果相同。
#
#   tool/benchmark/overlay.sh <worktree> [--app]
#
# - 总是复制: .fvmrc(两个版本用同一个 Flutter SDK)、L1 harness 与 packages/flexi_kline/test/benchmark/versioned/ 整个目录
#   (目录即版本对照的清单);
# - --app 另复制 apps/benchmark(integration_test/src/compat.dart 换成同目录的 compat_baseline.dart)
#   并登记到根 pubspec.yaml 的 workspace。
# - 来源: 相关目录没有未提交改动时取 HEAD 提交(git archive), 不读工作区: 目标版本正在同一个 app 目录里构建时,
#   工作区里的 build/、.dart_tool 在被改写, 复制会失败, 也不该进基线树; 有未提交改动(--allow-dirty)时才读工作区,
#   并跳过这些构建目录。
# - 内容没变就跳过(指纹写在 worktree 根的 .bench-overlay-id): 保留基线树里的 pub 解析和 Gradle / Xcode 增量缓存。
# 被覆盖的 worktree 就是当前树时什么都不做。
set -euo pipefail
source "$(dirname "$0")/lib.sh"

WT="${1:?usage: overlay.sh <worktree> [--app]}"
WT="$(cd "$WT" && pwd)"
[[ "$WT" == "$BENCH_ROOT" ]] && exit 0
APP=false
[[ "${2:-}" == "--app" ]] && APP=true

HARNESS=packages/flexi_kline/test/support/benchmark/bench_harness.dart
VERSIONED=packages/flexi_kline/test/benchmark/versioned
cd "$BENCH_ROOT"

CLEAN=false
if [[ -z "$(git status --porcelain --untracked-files=normal -- apps/benchmark "$HARNESS" "$VERSIONED" .fvmrc)" ]]; then
  CLEAN=true
fi

ID_FILE="$WT/.bench-overlay-id"
if $CLEAN; then
  ID="$(bench_code_id)"
  # 指纹相同就跳过; 带 app 的覆盖记作 "<id> app", 它也满足不带 app 的调用。
  if [[ -f "$ID_FILE" ]] && { [[ "$(cat "$ID_FILE")" == "$ID app" ]] || { ! $APP && [[ "$(cat "$ID_FILE")" == "$ID" ]]; }; }; then
    exit 0
  fi
fi
rm -f "$ID_FILE"

# 复制 HEAD 提交里的路径(干净时)或工作区里的路径(有未提交改动时)。
export_paths() {
  if $CLEAN; then
    git archive HEAD "$@" | tar -x -C "$WT"
  else
    tar --exclude=build --exclude=.dart_tool --exclude=.gradle -cf - "$@" | tar -x -C "$WT"
  fi
}

export_paths .fvmrc "$HARNESS"
rm -rf "$WT/$VERSIONED"
export_paths "$VERSIONED"

if $APP; then
  MANIFEST="$WT/.bench-overlay-files"
  if $CLEAN; then
    # 保留 worktree 里已有的构建缓存, 只删上次覆盖进来而这次已不存在的文件。
    NEW="$(git ls-tree -r --name-only HEAD -- apps/benchmark | sort)"
    if [[ -f "$MANIFEST" ]]; then
      comm -23 "$MANIFEST" <(printf '%s\n' "$NEW") | while IFS= read -r f; do rm -f "$WT/$f"; done
    fi
    printf '%s\n' "$NEW" >"$MANIFEST"
  else
    rm -rf "$WT/apps/benchmark"
    rm -f "$MANIFEST"
  fi
  export_paths apps/benchmark
  # 本机签名文件不入库, 但构建 iOS 需要。
  LOCAL=apps/benchmark/ios/Flutter/Local.xcconfig
  [[ ! -f "$LOCAL" ]] || cp "$LOCAL" "$WT/$LOCAL"
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
if $CLEAN; then
  if $APP; then echo "$ID app" >"$ID_FILE"; else echo "$ID" >"$ID_FILE"; fi
fi

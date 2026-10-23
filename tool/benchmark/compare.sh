#!/usr/bin/env bash
# 同机同口径对照两个版本的 L1 整帧 benchmark(packages/flexi_kline/test/benchmark/versioned/)。
#
#   tool/benchmark/compare.sh [--target HEAD] [--baseline <ref>] [--rounds 3] [--out build/benchmark/l1] [--allow-dirty]
#
# - 两个版本都跑当前树的 versioned/ 与 harness(overlay.sh), 场景逐字相同;
# - 按 B T B T ... 交替跑 --rounds 组, 降低机器状态漂移对单侧的影响;
# - 产出 micro-target.json、micro-baseline.json、gha.json、gha-speedup.json、summary.md、env.json。
#
# 只对照 versioned/: 其余微基准(merge、precompute、slot、draw_overlay)测的是当前实现的内部开销, API 跨版本变化大。
# target 是 HEAD 时要求工作区干净; --allow-dirty 只供本地调试, sha 记为 <sha>-dirty。
set -euo pipefail
source "$(dirname "$0")/lib.sh"
cd "$BENCH_ROOT"

TARGET="HEAD"
BASELINE=""
ROUNDS=3
OUT="build/benchmark/l1"
ALLOW_DIRTY=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --baseline) BASELINE="$2"; shift 2 ;;
    --rounds) ROUNDS="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --allow-dirty) ALLOW_DIRTY=true; shift ;;
    *) bench_die "unknown option: $1" ;;
  esac
done

if [[ "$(git rev-parse "$TARGET^{commit}")" == "$(git rev-parse HEAD)" ]]; then
  bench_require_clean "$ALLOW_DIRTY"
fi

FLUTTER="$(bench_dart flutter-version)"
case "$(uname -s)" in
  Darwin) CPU="$(sysctl -n machdep.cpu.brand_string)" ;;
  *) CPU="$(sed -n 's/^model name[[:space:]]*: //p' /proc/cpuinfo | head -1)" ;;
esac
HOST="$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m) $CPU"

mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"
rm -rf "$OUT/raw"

# 跑一组: 每个文件单独一次 flutter test, 某个文件在该版本编译或运行失败时只缺它, 不中断另一版本。
run_side() {
  local side="$1" tree="$2" ref="$3" round="$4" sha version out f log
  sha="$(bench_sha "$ref")"
  version="$(sed -n 's/^version: *//p' "$tree/packages/flexi_kline/pubspec.yaml")"
  out="$OUT/raw/$side/$round"
  mkdir -p "$out"
  for f in "$tree"/packages/flexi_kline/test/benchmark/versioned/*_test.dart; do
    log="$out/$(basename "$f" .dart).log"
    if ! (cd "$tree/packages/flexi_kline" && fvm flutter test "$f" --tags benchmark --concurrency=1 \
      --dart-define=FLEXI_BENCH_OUT="$out" \
      --dart-define=FLEXI_BENCH_SHA="$sha" \
      --dart-define=FLEXI_BENCH_VERSION="$version" \
      --dart-define=FLEXI_BENCH_FLUTTER="$FLUTTER" \
      --dart-define=FLEXI_BENCH_HOST="$HOST" >"$log" 2>&1); then
      echo "  $side round $round: $(basename "$f") failed (see $log)" >&2
    fi
  done
}

echo "preparing target $TARGET" >&2
bench_tree "$TARGET" target
TARGET_TREE="$TREE"
if [[ -n "$BASELINE" ]]; then
  echo "preparing baseline $BASELINE" >&2
  bench_tree "$BASELINE" baseline
  BASELINE_TREE="$TREE"
fi

for ((r = 1; r <= ROUNDS; r++)); do
  if [[ -n "$BASELINE" ]]; then
    echo "round $r/$ROUNDS: baseline" >&2
    run_side baseline "$BASELINE_TREE" "$BASELINE" "$r"
  fi
  echo "round $r/$ROUNDS: target" >&2
  run_side target "$TARGET_TREE" "$TARGET" "$r"
done

ENV=(rounds:="$ROUNDS" "target=$(bench_sha "$TARGET")" "flutter=$FLUTTER" "host=$HOST" "date=$(date -u +%Y-%m-%dT%H:%M:%SZ)")
[[ -n "$BASELINE" ]] && ENV+=("baseline=$(bench_sha "$BASELINE")")
bench_dart env "$OUT/env.json" "${ENV[@]}"

ARGS=(summarize micro --target "$OUT/raw/target" --out "$OUT")
[[ -n "$BASELINE" ]] && ARGS+=(--baseline "$OUT/raw/baseline")
bench_dart "${ARGS[@]}"

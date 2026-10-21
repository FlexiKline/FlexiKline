#!/usr/bin/env bash
# 同机同口径对照两个版本的 L1 整帧 benchmark。
#
#   tool/benchmark/compare.sh --target <ref> [--baseline <ref>] [--rounds 3] [--out build/benchmark/l1] [--allow-dirty]
#
# - 两个版本都跑当前树的 harness 与场景(overlay.sh), 场景逐字相同;
# - 按 B T B T ... 交替跑 --rounds 组, 降低机器状态漂移对单侧的影响;
# - 产出 micro-target.json、micro-baseline.json、gha.json、gha-speedup.json、summary.md、env.json。
#
# 结果要记被测代码的 sha, 所以工作区有未提交改动时拒绝运行; --allow-dirty 只供本地调试, sha 记为 <sha>-dirty。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

TARGET=""
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
    *) echo "unknown option: $1" >&2; exit 64 ;;
  esac
done
[[ -n "$TARGET" ]] || { echo "--target is required" >&2; exit 64; }

# 与 overlay.sh 的 FILES 保持一致(bench_chart.dart 是共用装配, 不单独跑)。
FILES=(test/benchmark/paint_frame_benchmark_test.dart test/benchmark/frame_scenarios_benchmark_test.dart)

DIRTY=""
if [[ -n "$(git status --porcelain --untracked-files=no)" ]]; then
  $ALLOW_DIRTY || { echo "working tree has uncommitted changes; commit first or pass --allow-dirty" >&2; exit 1; }
  DIRTY="-dirty"
fi

HEAD_SHA="$(git rev-parse HEAD)"
FLUTTER="$(fvm flutter --version --machine 2>/dev/null | sed -n 's/.*"frameworkVersion": *"\([^"]*\)".*/\1/p')"
case "$(uname -s)" in
  Darwin) CPU="$(sysctl -n machdep.cpu.brand_string)" ;;
  *) CPU="$(sed -n 's/^model name[[:space:]]*: //p' /proc/cpuinfo | head -1)" ;;
esac
HOST="$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m) $CPU"

mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"
rm -rf "$OUT/raw"
CREATED=()
# 只清理本次创建的 worktree; overlay 改过文件, 不加 --force 会被拒。已存在的(手动建的)保留。
cleanup() {
  for wt in "${CREATED[@]+"${CREATED[@]}"}"; do
    git worktree remove --force "$wt" >/dev/null 2>&1 || true
  done
}
trap cleanup EXIT

# 解析 ref 到可运行的树并写入 TREE: 就是 HEAD 时用当前树, 否则在 build/benchmark/wt/ 下 detach 一个 worktree。
# 不用 $(...) 返回: 子 shell 里追加的 CREATED 带不回来, 结束时就清理不到。
prepare() {
  local ref="$1" sha
  sha="$(git rev-parse "$ref^{commit}")"
  if [[ "$sha" == "$HEAD_SHA" ]]; then
    TREE="$ROOT"
    return
  fi
  TREE="$ROOT/build/benchmark/wt/${sha:0:10}"
  if [[ ! -d "$TREE" ]]; then
    git worktree add --detach "$TREE" "$sha" >/dev/null 2>&1
    CREATED+=("$TREE")
  fi
  tool/benchmark/overlay.sh "$TREE"
}

# 跑一组: 每个文件单独一次 flutter test, 某个文件在该版本编译或运行失败时只缺它, 不中断另一版本。
run_side() {
  local side="$1" tree="$2" ref="$3" round="$4" sha version out f
  sha="$(git rev-parse --short=10 "$ref^{commit}")"
  [[ "$tree" == "$ROOT" ]] && sha="$sha$DIRTY"
  version="$(sed -n 's/^version: *//p' "$tree/packages/flexi_kline/pubspec.yaml")"
  out="$OUT/raw/$side/$round"
  mkdir -p "$out"
  for f in "${FILES[@]}"; do
    if ! (cd "$tree/packages/flexi_kline" && fvm flutter test "$f" --tags benchmark --concurrency=1 \
      --dart-define=FLEXI_BENCH_OUT="$out" \
      --dart-define=FLEXI_BENCH_SHA="$sha" \
      --dart-define=FLEXI_BENCH_VERSION="$version" \
      --dart-define=FLEXI_BENCH_FLUTTER="$FLUTTER" \
      --dart-define=FLEXI_BENCH_HOST="$HOST" >"$out/$(basename "$f" .dart).log" 2>&1); then
      echo "  $side round $round: $f failed (see $out/$(basename "$f" .dart).log)" >&2
    fi
  done
}

echo "preparing target $TARGET" >&2
prepare "$TARGET"
TARGET_TREE="$TREE"
if [[ -n "$BASELINE" ]]; then
  echo "preparing baseline $BASELINE" >&2
  prepare "$BASELINE"
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

cat >"$OUT/env.json" <<EOF
{
  "target": "$(git rev-parse "$TARGET^{commit}")$DIRTY",
  "baseline": "$([[ -n "$BASELINE" ]] && git rev-parse "$BASELINE^{commit}")",
  "rounds": $ROUNDS,
  "flutter": "$FLUTTER",
  "host": "$HOST",
  "date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

ARGS=(l1 --target "$OUT/raw/target" --out "$OUT")
[[ -n "$BASELINE" ]] && ARGS+=(--baseline "$OUT/raw/baseline")
fvm dart run tool/benchmark/summarize.dart "${ARGS[@]}"

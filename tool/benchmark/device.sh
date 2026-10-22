#!/usr/bin/env bash
# 一次真机采集(L3): 在一台设备上跑一次 flutter drive, 结果写进 build/benchmark/device/。
#
#   tool/benchmark/device.sh --device <id> --hz <刷新率> [--side target|baseline] [--ref <ref>]
#       [--backend impeller|skia] [--label ios-phone] [--session adhoc]
#       [--binary <build.sh 打印的包> | --mode frames|trace --scenario 'pan/*' --windows 5 --window-seconds 10]
#       [--allow-dirty]
#
# - --side 只决定结果目录; --ref 决定代码, 默认 target 为 HEAD、baseline 为 v2.5.6-monorepo;
#   baseline 在 build/benchmark/wt/<sha> 运行, 由 overlay.sh --app 覆盖本 app;
# - --binary 直接安装 build.sh 的包, 采集参数取自包旁的 build.env, 不再构建; 否则 flutter drive 自己构建;
# - skia 只用于 Android(--no-enable-impeller); iOS 只有 Impeller;
# - --hz 用于核对: 设备实测刷新率与它相差超过 5% 时 bench_driver 报错, 不出数;
# - --label 覆盖目录名里的设备名(iOS 只能取到用户自定义的设备名)。
#
# 输出: build/benchmark/device/<session>/<label>-<backend>-<hz>hz/<side>/<UTC 时间>/{env.json,frames.json,drive.log}
# 同一组合的多次运行落在同一个 <side> 目录下, 供 `bench.dart summarize device` 合并。
set -euo pipefail
source "$(dirname "$0")/lib.sh"
cd "$BENCH_ROOT"

DEVICE=""
HZ=""
SIDE="target"
REF=""
BACKEND="impeller"
LABEL=""
SESSION="adhoc"
BINARY=""
MODE="frames"
SCENARIO=""
WINDOWS=5
WINDOW_SECONDS=10
ALLOW_DIRTY=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --device) DEVICE="$2"; shift 2 ;;
    --hz) HZ="$2"; shift 2 ;;
    --side) SIDE="$2"; shift 2 ;;
    --ref) REF="$2"; shift 2 ;;
    --backend) BACKEND="$2"; shift 2 ;;
    --label) LABEL="$2"; shift 2 ;;
    --session) SESSION="$2"; shift 2 ;;
    --binary) BINARY="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    --scenario) SCENARIO="$2"; shift 2 ;;
    --windows) WINDOWS="$2"; shift 2 ;;
    --window-seconds) WINDOW_SECONDS="$2"; shift 2 ;;
    --allow-dirty) ALLOW_DIRTY=true; shift ;;
    *) bench_die "unknown option: $1" ;;
  esac
done
[[ -n "$DEVICE" ]] || bench_die "--device is required"
[[ -n "$HZ" ]] || bench_die "--hz is required"
[[ "$SIDE" == target || "$SIDE" == baseline ]] || bench_die "--side must be target or baseline"
[[ "$BACKEND" == impeller || "$BACKEND" == skia ]] || bench_die "--backend must be impeller or skia"
[[ "$MODE" == frames || "$MODE" == trace ]] || bench_die "--mode must be frames or trace"

read -r KIND MODEL OS < <(bench_dart device-info "$DEVICE")
[[ "$BACKEND" == skia && "$KIND" == ios ]] && bench_die "iOS has no Skia backend"

ARGS=(drive --profile -d "$DEVICE" --driver=test_driver/bench_driver.dart --target=integration_test/bench_test.dart)
if [[ -n "$BINARY" ]]; then
  [[ -e "$BINARY" ]] || bench_die "no binary at $BINARY; run tool/benchmark/build.sh first"
  # shellcheck source=/dev/null
  source "$(dirname "$BINARY")/build.env"
  REF="$BUILD_REF" SHA="$BUILD_SHA" MODE="$BUILD_MODE" SCENARIO="$BUILD_SCENARIO"
  WINDOWS="$BUILD_WINDOWS" WINDOW_SECONDS="$BUILD_WINDOW_SECONDS"
  # driver 两版逐字相同, 从当前树跑, 不碰基线树: 多台设备并行时就不会同时改写它。
  APP_DIR="$BENCH_ROOT/apps/benchmark"
  ARGS+=(--use-application-binary="$BINARY")
else
  [[ -n "$REF" ]] || { [[ "$SIDE" == baseline ]] && REF="v2.5.6-monorepo" || REF="HEAD"; }
  [[ "$(git rev-parse "$REF^{commit}")" == "$(git rev-parse HEAD)" ]] && bench_require_clean "$ALLOW_DIRTY"
  SHA="$(bench_sha "$REF")"
  bench_tree "$REF" --app
  APP_DIR="$TREE/apps/benchmark"
  ARGS+=(--dart-define=MODE="$MODE" --dart-define=WINDOWS="$WINDOWS" --dart-define=WINDOW_SECONDS="$WINDOW_SECONDS")
  [[ -n "$SCENARIO" ]] && ARGS+=(--dart-define=SCENARIO="$SCENARIO")
fi
[[ "$BACKEND" == skia ]] && ARGS+=(--no-enable-impeller)

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
SLUG="$(printf '%s' "${LABEL:-$MODEL}" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9-' '-' | sed 's/--*/-/g; s/^-//; s/-$//')"
OUT="$BENCH_ROOT/build/benchmark/device/$SESSION/$SLUG-$BACKEND-${HZ}hz/$SIDE/$STAMP"
[[ "$MODE" == trace ]] && OUT="$OUT-trace"
mkdir -p "$OUT"

VERSION="$(git show "$REF:packages/flexi_kline/pubspec.yaml" | sed -n 's/^version: *//p')"
bench_dart env "$OUT/env.json" "version=$VERSION" "sha=$SHA" "flutter=$(bench_dart flutter-version)" \
  "device=$MODEL" "os=$OS" "platform=$KIND" "backend=$BACKEND" hz:="$HZ" "mode=$MODE" \
  "scenario=${SCENARIO:-all}" windows:="$WINDOWS" windowSeconds:="$WINDOW_SECONDS" "date=$STAMP"

echo "device $MODEL ($OS, $BACKEND, ${HZ}Hz), $SIDE $VERSION ($SHA) -> $OUT" >&2
cd "$APP_DIR"
START="$(date +%s)"
# 首次 Android profile 构建可能十几分钟无输出, 有开始时间才分得清是慢还是卡住。
echo "[$(date +%H:%M:%S)] building & driving..." >&2
# pipefail: drive 失败时脚本以非零退出, 编排脚本据此记失败。
FLEXI_BENCH_DEVICE_OUT="$OUT" FLEXI_BENCH_HZ="$HZ" fvm flutter "${ARGS[@]}" 2>&1 | tee "$OUT/drive.log"
echo "[$(date +%H:%M:%S)] done in $(($(date +%s) - START))s" >&2

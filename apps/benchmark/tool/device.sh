#!/usr/bin/env bash
# 一次真机采集(L3): profile 构建, 跑 integration_test/frames_test.dart, 结果写进 build/benchmark/device/。
#
#   apps/benchmark/tool/device.sh --device <id> --version <current|baseline> --hz <60|90|120|165>
#       [--baseline-ref v2.5.6-monorepo] [--backend impeller|skia] [--mode frames|trace] [--scenario pan/multi]
#       [--windows 5] [--window-seconds 10] [--label iphone16] [--session adhoc] [--build | --prebuilt] [--allow-dirty]
#
# - baseline: 在 build/benchmark/wt/<sha> 准备 --baseline-ref, 用 tool/benchmark/overlay.sh --app 覆盖本 app;
# - skia 只用于 Android(--no-enable-impeller); iOS 只有 Impeller;
# - --label 覆盖目录名里的设备名(iOS 只能取到用户自定义的设备名);
# - --hz 用于核对: 设备实测刷新率与它相差超过 5% 时 perf_driver 报错, 不出数;
# - --build 只构建安装包到 build/benchmark/bin/ 后退出; --prebuilt 直接装这个包, 不再构建。
#   dart-define 是编译期常量, 包按 版本 sha + 平台 + mode/windows/scenario 区分, 两边参数须一致;
# - 结果要记被测代码的 sha, 工作区有未提交改动时拒绝运行; --allow-dirty 只供冒烟, sha 记为 <sha>-dirty。
#
# 输出: build/benchmark/device/<session>/<device>-<backend>-<hz>hz/<version>/<UTC 时间>/{env.json,frames.json,drive.log}
# 同一组合多次运行落在同一个 <version> 目录下, 供 `summarize.dart l3` 合并。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$ROOT"

BASELINE_REF="v2.5.6-monorepo"
DEVICE=""
VERSION=""
HZ=""
BACKEND="impeller"
MODE="frames"
SCENARIO=""
WINDOWS=5
WINDOW_SECONDS=10
LABEL=""
SESSION="adhoc"
BUILD=false
PREBUILT=false
ALLOW_DIRTY=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --device) DEVICE="$2"; shift 2 ;;
    --version) VERSION="$2"; shift 2 ;;
    --baseline-ref) BASELINE_REF="$2"; shift 2 ;;
    --hz) HZ="$2"; shift 2 ;;
    --backend) BACKEND="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    --scenario) SCENARIO="$2"; shift 2 ;;
    --windows) WINDOWS="$2"; shift 2 ;;
    --window-seconds) WINDOW_SECONDS="$2"; shift 2 ;;
    --label) LABEL="$2"; shift 2 ;;
    --session) SESSION="$2"; shift 2 ;;
    --build) BUILD=true; shift ;;
    --prebuilt) PREBUILT=true; shift ;;
    --allow-dirty) ALLOW_DIRTY=true; shift ;;
    *) echo "unknown option: $1" >&2; exit 64 ;;
  esac
done
[[ -n "$DEVICE" ]] || { echo "--device is required" >&2; exit 64; }
$BUILD || [[ -n "$HZ" ]] || { echo "--hz is required" >&2; exit 64; }
[[ "$VERSION" == current || "$VERSION" == baseline ]] || { echo "--version must be current or baseline" >&2; exit 64; }
[[ "$BACKEND" == impeller || "$BACKEND" == skia ]] || { echo "--backend must be impeller or skia" >&2; exit 64; }
[[ "$MODE" == frames || "$MODE" == trace ]] || { echo "--mode must be frames or trace" >&2; exit 64; }

DIRTY=""
if [[ -n "$(git status --porcelain --untracked-files=no)" ]]; then
  $ALLOW_DIRTY || { echo "working tree has uncommitted changes; commit first or pass --allow-dirty" >&2; exit 1; }
  DIRTY="-dirty"
fi

# 设备信息: flutter devices --machine 里取平台、型号与系统版本; Android 型号用 getprop, 不用用户自定义的设备名。
DEVICE_JSON="$(fvm flutter devices --machine 2>/dev/null)"
read -r PLATFORM NAME OS < <(python3 -c '
import json, sys
dev = next((d for d in json.load(sys.stdin) if d["id"] == sys.argv[1]), None)
if dev is None:
    sys.exit("device %s not found" % sys.argv[1])
print(dev["targetPlatform"], dev["name"].replace(" ", "_"), dev["sdk"].replace(" ", "_"))
' "$DEVICE" <<<"$DEVICE_JSON")
[[ -n "${PLATFORM:-}" ]] || { echo "device $DEVICE not found in flutter devices" >&2; exit 1; }
case "$PLATFORM" in
  ios) MODEL="$NAME"; KIND=ios ;;
  android*)
    MODEL="$(adb -s "$DEVICE" shell getprop ro.product.model | tr -d '\r' | tr ' ' '_')"
    OS="Android_$(adb -s "$DEVICE" shell getprop ro.build.version.release | tr -d '\r')"
    KIND=android
    ;;
  *) echo "unsupported platform $PLATFORM" >&2; exit 1 ;;
esac
if [[ "$BACKEND" == skia && "$KIND" == ios ]]; then
  echo "iOS has no Skia backend" >&2
  exit 64
fi

if [[ "$VERSION" == baseline ]]; then
  REF="$BASELINE_REF"
  SHA="$(git rev-parse --short=10 "$REF^{commit}")"
  TREE="$ROOT/build/benchmark/wt/$SHA"
else
  REF="HEAD"
  SHA="$(git rev-parse --short=10 HEAD)$DIRTY"
  TREE="$ROOT"
fi

DEFINES=(--dart-define=MODE="$MODE" --dart-define=WINDOWS="$WINDOWS" --dart-define=WINDOW_SECONDS="$WINDOW_SECONDS")
[[ -n "$SCENARIO" ]] && DEFINES+=(--dart-define=SCENARIO="$SCENARIO")
BIN_DIR="$ROOT/build/benchmark/bin/$SHA-$KIND-$MODE-${WINDOWS}x$WINDOW_SECONDS${SCENARIO:+-${SCENARIO//\//_}}"
case "$KIND" in
  ios) BIN="$BIN_DIR/Runner.app" ;;
  android) BIN="$BIN_DIR/app-profile.apk" ;;
esac

# 基线树: 构建或不用预构建包时才准备; 预构建时 driver 从当前树跑(两边 driver 逐字相同), 不碰基线树,
# 多台设备并行时就不会同时改写它。
if [[ "$VERSION" == baseline ]] && ! $PREBUILT; then
  [[ -d "$TREE" ]] || git worktree add --detach "$TREE" "$REF" >/dev/null
  tool/benchmark/overlay.sh "$TREE" --app
fi

if $BUILD; then
  echo "building $KIND $VERSION ($SHA) -> $BIN" >&2
  cd "$TREE/apps/benchmark"
  case "$KIND" in
    ios)
      fvm flutter build ios --profile --target=integration_test/frames_test.dart "${DEFINES[@]}"
      OUT_BIN=build/ios/iphoneos/Runner.app
      ;;
    android)
      fvm flutter build apk --profile --target=integration_test/frames_test.dart "${DEFINES[@]}"
      OUT_BIN=build/app/outputs/flutter-apk/app-profile.apk
      ;;
  esac
  mkdir -p "$BIN_DIR"
  rm -rf "$BIN"
  cp -R "$OUT_BIN" "$BIN"
  exit 0
fi
if $PREBUILT; then
  [[ -e "$BIN" ]] || { echo "no prebuilt binary at $BIN; run with --build first" >&2; exit 1; }
fi

PKG_VERSION="$(git show "$REF:packages/flexi_kline/pubspec.yaml" | sed -n 's/^version: *//p')"
FLUTTER="$(fvm flutter --version --machine 2>/dev/null | sed -n 's/.*"frameworkVersion": *"\([^"]*\)".*/\1/p')"

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
SLUG="$(printf '%s' "${LABEL:-$MODEL}" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9-' '-' | sed 's/--*/-/g; s/^-//; s/-$//')"
OUT="$ROOT/build/benchmark/device/$SESSION/$SLUG-$BACKEND-${HZ}hz/$VERSION/$STAMP"
[[ "$MODE" == trace ]] && OUT="$OUT-trace"
mkdir -p "$OUT"

cat >"$OUT/env.json" <<EOF
{
  "version": "$PKG_VERSION",
  "sha": "$SHA",
  "flutter": "$FLUTTER",
  "device": "$MODEL",
  "os": "$OS",
  "platform": "$PLATFORM",
  "backend": "$BACKEND",
  "hz": $HZ,
  "mode": "$MODE",
  "scenario": "${SCENARIO:-all}",
  "windows": $WINDOWS,
  "windowSeconds": $WINDOW_SECONDS,
  "date": "$STAMP"
}
EOF

ARGS=(drive --profile -d "$DEVICE" --driver=test_driver/perf_driver.dart --target=integration_test/frames_test.dart)
if $PREBUILT; then
  ARGS+=(--use-application-binary="$BIN")
  APP_DIR="$ROOT/apps/benchmark"
else
  ARGS+=("${DEFINES[@]}")
  APP_DIR="$TREE/apps/benchmark"
fi
[[ "$BACKEND" == skia ]] && ARGS+=(--no-enable-impeller)

echo "device $MODEL ($OS, $BACKEND, ${HZ}Hz), $VERSION $PKG_VERSION ($SHA) -> $OUT" >&2
cd "$APP_DIR"
# pipefail: drive 失败时脚本以非零退出, 编排脚本据此记失败。
FLEXI_BENCH_DEVICE_OUT="$OUT" FLEXI_BENCH_HZ="$HZ" fvm flutter "${ARGS[@]}" 2>&1 | tee "$OUT/drive.log"

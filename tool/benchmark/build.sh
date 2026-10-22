#!/usr/bin/env bash
# 构建真机基准包(profile), 供 device.sh --binary 反复安装; 打印包路径。
#
#   tool/benchmark/build.sh --platform ios|android [--ref HEAD] [--mode frames|trace] [--scenario 'pan/*']
#       [--windows 5] [--window-seconds 10] [--allow-dirty]
#
# dart-define 是编译期常量, 所以包按 sha + 平台 + 参数存放在 build/benchmark/bin/<key>/,
# 旁边的 build.env 记下这些参数, device.sh 据此写 env.json, 不再重复传。
# 同一干净 sha 的包已存在时直接复用; 带未提交改动(--allow-dirty)时每次重建。
set -euo pipefail
source "$(dirname "$0")/lib.sh"
cd "$BENCH_ROOT"

PLATFORM=""
REF="HEAD"
MODE="frames"
SCENARIO=""
WINDOWS=5
WINDOW_SECONDS=10
ALLOW_DIRTY=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --platform) PLATFORM="$2"; shift 2 ;;
    --ref) REF="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    --scenario) SCENARIO="$2"; shift 2 ;;
    --windows) WINDOWS="$2"; shift 2 ;;
    --window-seconds) WINDOW_SECONDS="$2"; shift 2 ;;
    --allow-dirty) ALLOW_DIRTY=true; shift ;;
    *) bench_die "unknown option: $1" ;;
  esac
done
[[ "$PLATFORM" == ios || "$PLATFORM" == android ]] || bench_die "--platform must be ios or android"
[[ "$MODE" == frames || "$MODE" == trace ]] || bench_die "--mode must be frames or trace"

[[ "$(git rev-parse "$REF^{commit}")" == "$(git rev-parse HEAD)" ]] && bench_require_clean "$ALLOW_DIRTY"
SHA="$(bench_sha "$REF")"
KEY="$SHA-$PLATFORM-$MODE-${WINDOWS}x$WINDOW_SECONDS${SCENARIO:+-$(printf '%s' "$SCENARIO" | tr -c 'a-zA-Z0-9-' '_')}"
DIR="$BENCH_ROOT/build/benchmark/bin/$KEY"
case "$PLATFORM" in
  ios) BIN="$DIR/Runner.app" OUT_BIN=build/ios/iphoneos/Runner.app ;;
  android) BIN="$DIR/app-profile.apk" OUT_BIN=build/app/outputs/flutter-apk/app-profile.apk ;;
esac

if [[ -e "$BIN" && -z "${DIRTY:-}" ]]; then
  echo "$BIN"
  exit 0
fi

bench_tree "$REF" --app
DEFINES=(--dart-define=MODE="$MODE" --dart-define=WINDOWS="$WINDOWS" --dart-define=WINDOW_SECONDS="$WINDOW_SECONDS")
[[ -n "$SCENARIO" ]] && DEFINES+=(--dart-define=SCENARIO="$SCENARIO")
echo "building $PLATFORM $REF ($SHA) -> $BIN" >&2
case "$PLATFORM" in
  ios) (cd "$TREE/apps/benchmark" && fvm flutter build ios --profile --target=integration_test/bench_test.dart "${DEFINES[@]}") >&2 ;;
  android) (cd "$TREE/apps/benchmark" && fvm flutter build apk --profile --target=integration_test/bench_test.dart "${DEFINES[@]}") >&2 ;;
esac
mkdir -p "$DIR"
rm -rf "$BIN"
cp -R "$TREE/apps/benchmark/$OUT_BIN" "$BIN"
cat >"$DIR/build.env" <<EOF
BUILD_REF='$REF'
BUILD_SHA='$SHA'
BUILD_MODE='$MODE'
BUILD_SCENARIO='$SCENARIO'
BUILD_WINDOWS='$WINDOWS'
BUILD_WINDOW_SECONDS='$WINDOW_SECONDS'
EOF
echo "$BIN"

#!/usr/bin/env bash
# 多台真机的一轮完整采集: 每版本每平台构建一次、按刷新率分阶段、设备间并行、版本交替, 最后出对照表。
#
#   tool/benchmark/matrix.sh [--devices tool/benchmark/devices.conf] [--baseline-ref v2.5.6-monorepo] [--no-baseline]
#       [--rounds 2] [--windows 5] [--window-seconds 10] [--cooldown 120] [--session <name>] [--publish] [--allow-dirty]
#
# devices.conf 每行一个组合 `<label> <device-id> <hz> <backend>`, 见 devices.example.conf。
# 同一设备的不同刷新率分在不同阶段: 阶段之间脚本暂停, 等你在手机上切好刷新率后回车。
#
# 每台设备在每个阶段按 B T B T ... 交替跑 --rounds 组(--no-baseline 时只跑 T), 两次运行之间冷却 --cooldown 秒。
# 产出 build/benchmark/device/<session>/<combo>/{device.json,device-summary.md} 与汇总 summary.md;
# --publish 再复制到 docs/benchmark/results/<session>/(不含原始帧数据)。
# 某次运行失败不中断其他设备; 结束时列出失败项, 可用 device.sh 加同一个 --session 补跑, summarize 会合并。
set -euo pipefail
source "$(dirname "$0")/lib.sh"
cd "$BENCH_ROOT"

CONF="tool/benchmark/devices.conf"
BASELINE_REF="v2.5.6-monorepo"
SIDES=(baseline target)
ROUNDS=2
WINDOWS=5
WINDOW_SECONDS=10
COOLDOWN=120
SESSION="$(date +%Y%m%d-%H%M)"
PUBLISH=false
DIRTY_ARG=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --devices) CONF="$2"; shift 2 ;;
    --baseline-ref) BASELINE_REF="$2"; shift 2 ;;
    --no-baseline) SIDES=(target); shift ;;
    --rounds) ROUNDS="$2"; shift 2 ;;
    --windows) WINDOWS="$2"; shift 2 ;;
    --window-seconds) WINDOW_SECONDS="$2"; shift 2 ;;
    --cooldown) COOLDOWN="$2"; shift 2 ;;
    --session) SESSION="$2"; shift 2 ;;
    --publish) PUBLISH=true; shift ;;
    --allow-dirty) DIRTY_ARG=(--allow-dirty); shift ;;
    *) bench_die "unknown option: $1" ;;
  esac
done
[[ -f "$CONF" ]] || bench_die "no $CONF; copy tool/benchmark/devices.example.conf and fill in device ids"
bench_require_clean "$([[ ${#DIRTY_ARG[@]} -gt 0 ]] && echo true || echo false)"

OUT="build/benchmark/device/$SESSION"
mkdir -p "$OUT"
PLAN="$(bench_dart plan "$CONF")"
echo "plan (phase label id hz backend platform):" >&2
echo "$PLAN" | sed 's/^/  /' >&2

# 电量: Android 用 adb 读; iOS 没有免装工具可读, 只提醒。
while read -r id; do
  level="$(adb -s "$id" shell dumpsys battery | sed -n 's/^ *level: *//p' | tr -d '\r')"
  [[ "${level:-0}" -ge 50 ]] || echo "warning: $id battery ${level:-?}% (< 50%)" >&2
done < <(echo "$PLAN" | awk '$6 == "android" { print $3 }' | sort -u)
echo "reminder: keep iOS devices above 50% battery, unplugged from power where possible, brightness fixed" >&2

# 构建: 每个版本、每个平台一次; 之后所有运行都装这个包。BIN_<side>_<platform> 记包路径。
for side in "${SIDES[@]}"; do
  ref="HEAD"
  [[ "$side" == baseline ]] && ref="$BASELINE_REF"
  for platform in $(echo "$PLAN" | awk '{ print $6 }' | sort -u); do
    bin="$(tool/benchmark/build.sh --platform "$platform" --ref "$ref" --windows "$WINDOWS" \
      --window-seconds "$WINDOW_SECONDS" "${DIRTY_ARG[@]+"${DIRTY_ARG[@]}"}")"
    printf -v "BIN_${side}_$platform" '%s' "$bin"
  done
done

# 一台设备在一个阶段里的全部运行, 后台执行; 失败记进 failures 文件, 不中断。
run_device() {
  local phase="$1" label="$2" log="$OUT/$label.log" r side bin first=true
  for ((r = 1; r <= ROUNDS; r++)); do
    for side in "${SIDES[@]}"; do
      while read -r _ _ id hz backend platform; do
        $first || sleep "$COOLDOWN"
        first=false
        bin="BIN_${side}_$platform"
        if ! tool/benchmark/device.sh --device "$id" --hz "$hz" --side "$side" --backend "$backend" --label "$label" \
          --session "$SESSION" --binary "${!bin}" </dev/null >>"$log" 2>&1; then
          echo "$label ${hz}Hz $backend $side round $r" >>"$OUT/failures"
        fi
      done < <(echo "$PLAN" | awk -v p="$phase" -v l="$label" '$1 == p && $2 == l')
    done
  done
}

rm -f "$OUT/failures"
for phase in $(echo "$PLAN" | awk '{ print $1 }' | sort -nu); do
  echo >&2
  echo "phase $phase: set these refresh rates, keep the screens on, then press Enter" >&2
  echo "$PLAN" | awk -v p="$phase" '$1 == p { print "  " $2 ": " $4 "Hz" }' | sort -u >&2
  read -r </dev/tty
  pids=()
  for label in $(echo "$PLAN" | awk -v p="$phase" '$1 == p { print $2 }' | sort -u); do
    echo "phase $phase: $label started, log $OUT/$label.log" >&2
    run_device "$phase" "$label" &
    pids+=($!)
    # 错开启动: 几个 flutter drive 同时解析同一个工程时会争用 .dart_tool。
    sleep 20
  done
  wait "${pids[@]}" || true
done

for combo in "$OUT"/*/; do
  [[ -d "$combo/target" ]] || continue
  args=(summarize device --target "$combo/target" --out "$combo")
  [[ -d "$combo/baseline" ]] && args+=(--baseline "$combo/baseline")
  bench_dart "${args[@]}" >/dev/null
done
if ls "$OUT"/*/device-summary.md >/dev/null 2>&1; then
  cat "$OUT"/*/device-summary.md >"$OUT/summary.md"
  echo "summary: $OUT/summary.md" >&2
fi

if $PUBLISH; then
  DOCS="docs/benchmark/results/$SESSION"
  for combo in "$OUT"/*/; do
    [[ -f "$combo/device.json" ]] || continue
    mkdir -p "$DOCS/$(basename "$combo")"
    cp "$combo/device.json" "$combo/device-summary.md" "$DOCS/$(basename "$combo")/"
  done
  [[ -f "$OUT/summary.md" ]] && cp "$OUT/summary.md" "$DOCS/"
  echo "published to $DOCS" >&2
fi

if [[ -f "$OUT/failures" ]]; then
  echo "failed runs (see $OUT/<label>.log):" >&2
  sed 's/^/  /' "$OUT/failures" >&2
  exit 1
fi

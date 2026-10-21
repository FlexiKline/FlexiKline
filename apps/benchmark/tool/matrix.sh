#!/usr/bin/env bash
# 多台真机的一轮完整采集: 构建一次、按刷新率分阶段、设备间并行、版本交替, 最后出对照表。
#
#   apps/benchmark/tool/matrix.sh [--devices apps/benchmark/tool/devices.conf] [--baseline-ref v2.5.6-monorepo]
#       [--current-only] [--rounds 2] [--windows 3] [--window-seconds 10] [--cooldown 120]
#       [--session <name>] [--publish] [--allow-dirty]
#
# devices.conf 每行一个组合 `<label> <device-id> <hz> <backend>`, 见 devices.example.conf。
# 同一设备的不同刷新率分在不同阶段: 阶段之间脚本暂停, 等你在手机上切好刷新率后回车。
#
# 每台设备在每个阶段按 B T B T ... 交替跑 --rounds 组(--current-only 时只跑 T), 组之间冷却 --cooldown 秒。
# 产出 build/benchmark/device/<session>/<combo>/{device.json,device-summary.md} 与汇总 summary.md;
# --publish 再复制到 docs/benchmark/results/<session>/(不含原始帧数据)。
# 某次运行失败不中断其他设备; 结束时列出失败项, 可用 device.sh 加同一个 --session 补跑, summarize 会合并。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$ROOT"
DEVICE_SH="apps/benchmark/tool/device.sh"

CONF="apps/benchmark/tool/devices.conf"
BASELINE_REF="v2.5.6-monorepo"
CURRENT_ONLY=false
ROUNDS=2
WINDOWS=3
WINDOW_SECONDS=10
COOLDOWN=120
SESSION="$(date +%Y%m%d-%H%M)"
PUBLISH=false
DIRTY_ARG=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --devices) CONF="$2"; shift 2 ;;
    --baseline-ref) BASELINE_REF="$2"; shift 2 ;;
    --current-only) CURRENT_ONLY=true; shift ;;
    --rounds) ROUNDS="$2"; shift 2 ;;
    --windows) WINDOWS="$2"; shift 2 ;;
    --window-seconds) WINDOW_SECONDS="$2"; shift 2 ;;
    --cooldown) COOLDOWN="$2"; shift 2 ;;
    --session) SESSION="$2"; shift 2 ;;
    --publish) PUBLISH=true; shift ;;
    --allow-dirty) DIRTY_ARG=(--allow-dirty); shift ;;
    *) echo "unknown option: $1" >&2; exit 64 ;;
  esac
done
[[ -f "$CONF" ]] || { echo "no $CONF; copy apps/benchmark/tool/devices.example.conf and fill in device ids" >&2; exit 64; }
if [[ ${#DIRTY_ARG[@]} -eq 0 && -n "$(git status --porcelain --untracked-files=no)" ]]; then
  echo "working tree has uncommitted changes; commit first or pass --allow-dirty" >&2
  exit 1
fi

VERSIONS=(baseline current)
$CURRENT_ONLY && VERSIONS=(current)
COMMON=(--baseline-ref "$BASELINE_REF" --windows "$WINDOWS" --window-seconds "$WINDOW_SECONDS" "${DIRTY_ARG[@]+"${DIRTY_ARG[@]}"}")
OUT="build/benchmark/device/$SESSION"
mkdir -p "$OUT"

# 组合表: `<phase> <label> <id> <hz> <backend> <kind>`; phase 是该 hz 在本设备各档里从低到高的序号。
DEVICE_JSON="$(fvm flutter devices --machine 2>/dev/null)"
PLAN="$(python3 -c '
import json, sys
devices = {d["id"]: d["targetPlatform"] for d in json.loads(sys.argv[1])}
rows, missing = [], set()
for line in open(sys.argv[2]):
    line = line.split("#")[0].split()
    if not line:
        continue
    label, dev, hz, backend = line
    if dev not in devices:
        missing.add("%s (%s)" % (label, dev))
        continue
    rows.append((label, dev, int(hz), backend, "ios" if devices[dev] == "ios" else "android"))
if missing:
    sys.exit("not connected: " + ", ".join(sorted(missing)))
for label, dev, hz, backend, kind in rows:
    phase = sorted({r[2] for r in rows if r[0] == label}).index(hz) + 1
    print(phase, label, dev, hz, backend, kind)
' "$DEVICE_JSON" "$CONF")"
echo "plan (phase label id hz backend platform):" >&2
echo "$PLAN" | sed 's/^/  /' >&2

# 电量: Android 用 adb 读; iOS 没有免装工具可读, 只提醒。
for id in $(echo "$PLAN" | awk '$6 == "android" { print $3 }' | sort -u); do
  level="$(adb -s "$id" shell dumpsys battery | sed -n 's/^ *level: *//p' | tr -d '\r')"
  [[ "${level:-0}" -ge 50 ]] || echo "warning: $id battery ${level:-?}% (< 50%)" >&2
done
echo "reminder: keep iOS devices above 50% battery, unplugged from power where possible, brightness fixed" >&2

# 构建: 每个版本、每个平台一次, 用该平台第一台设备; 之后所有运行都装这个包。
for version in "${VERSIONS[@]}"; do
  for id in $(echo "$PLAN" | awk '!seen[$6]++ { print $3 }'); do
    "$DEVICE_SH" --device "$id" --version "$version" --build "${COMMON[@]}"
  done
done

# 一台设备在一个阶段里的全部运行, 后台执行; 失败记进 failures 文件, 不中断。
run_device() {
  local phase="$1" label="$2" log="$OUT/$label.log" r version
  for ((r = 1; r <= ROUNDS; r++)); do
    for version in "${VERSIONS[@]}"; do
      echo "$PLAN" | awk -v p="$phase" -v l="$label" '$1 == p && $2 == l' | while read -r _ _ id hz backend _; do
        if ! "$DEVICE_SH" --device "$id" --version "$version" --hz "$hz" --backend "$backend" --label "$label" \
          --session "$SESSION" --prebuilt "${COMMON[@]}" </dev/null >>"$log" 2>&1; then
          echo "$label $hz ${backend} $version round $r" >>"$OUT/failures"
        fi
        sleep "$COOLDOWN"
      done
    done
  done
}

rm -f "$OUT/failures"
PHASES="$(echo "$PLAN" | awk '{ print $1 }' | sort -n | uniq)"
for phase in $PHASES; do
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
  [[ -d "$combo/current" ]] || continue
  args=(l3 --target "$combo/current" --out "$combo")
  [[ -d "$combo/baseline" ]] && args+=(--baseline "$combo/baseline")
  fvm dart run tool/benchmark/summarize.dart "${args[@]}" >/dev/null
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

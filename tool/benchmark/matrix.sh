#!/usr/bin/env bash
# 多台真机采集: 每版本每平台构建一次, 设备间并行, 每台按基线、当前交替, 最后出对照表。
# 一次调用只跑一个刷新率, 启动后无人值守; 高刷、低刷各调用一次, 用同一个 --session 合并结果:
#
#   tool/benchmark/matrix.sh --session <名字> --hz 60 [--publish]
#
# 选项(括号内为默认): --devices (tool/benchmark/devices.conf)  --hz <只跑该刷新率的行>  --only <label[,label]>
#   --backend impeller|skia|all (impeller)  --side baseline|target  --baseline (v2.5.6-monorepo)  --no-baseline
#   --rounds (2)  --windows (3)  --window-seconds (6)  --cooldown (120)  --session (当前时间)  --publish  --allow-dirty
#
# - 启动前核对: 选中设备在线、每台只剩一个刷新率、Android 屏幕刷新率与配置相差不超过 5%; 不满足就退出, 不开始运行。
# - 构建: 两个版本并行, 日志在 build-<side>.log; 包按 sha 缓存, 同一提交再跑不重建。
# - 两次运行之间按温度冷却: Android 等电池温度回到开跑时 +1°C 以内(最多 --cooldown 秒), iOS 固定 60s。
# - 每次运行前: 设备最多等 120s 上线, Android 再核对一次刷新率; 不满足时这台设备剩下的运行记为失败并跳过, 其他设备继续。
# - 产出 build/benchmark/device/<session>/<combo>/ 与 summary.md; --publish 再把摘要复制到 docs/benchmark/results/<session>/。
# - 有失败时写 retry-<UTC>.sh(每次调用一份), 执行它补采; summarize 会合并补采结果。
set -euo pipefail
source "$(dirname "$0")/lib.sh"
cd "$BENCH_ROOT"

CONF="tool/benchmark/devices.conf"
HZ=""
ONLY=""
BACKEND="impeller"
BASELINE="v2.5.6-monorepo"
SIDES=(baseline target)
ROUNDS=2
WINDOWS=3
WINDOW_SECONDS=6
COOLDOWN=120
SESSION="$(date +%Y%m%d-%H%M)"
PUBLISH=false
DIRTY_ARG=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --devices) CONF="$2"; shift 2 ;;
    --hz) HZ="$2"; shift 2 ;;
    --only) ONLY="$2"; shift 2 ;;
    --backend) BACKEND="$2"; shift 2 ;;
    --baseline) BASELINE="$2"; shift 2 ;;
    --no-baseline) SIDES=(target); shift ;;
    --side) SIDES=("$2"); shift 2 ;;
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
[[ "$BACKEND" =~ ^(impeller|skia|all)$ ]] || bench_die "--backend must be impeller, skia or all"
[[ "${SIDES[0]}" =~ ^(baseline|target)$ ]] || bench_die "--side must be baseline or target"
bench_require_clean "$([[ ${#DIRTY_ARG[@]} -gt 0 ]] && echo true || echo false)"

# 下面的 adb / dart 调用都接 </dev/null: 它们在 `while read` 循环里执行, 会吃掉循环剩下的输入行。
wait_online() {
  local i
  for ((i = 0; i <= 12; i++)); do
    bench_dart device-info "$1" </dev/null >/dev/null 2>&1 && return
    ((i < 12)) && sleep 10
  done
  return 1
}

# Android 屏幕刷新率(整数 Hz); 读不到时为空。
display_hz() {
  adb -s "$1" shell dumpsys display </dev/null 2>/dev/null \
    | sed -n 's/.*mActiveSfDisplayMode.*peakRefreshRate=\([0-9][0-9]*\).*/\1/p' | head -1
}

# 实测 $1 与期望 $2 相差不超过 5%, 与 bench_driver 的核对口径一致。
hz_ok() {
  local d=$((${1:-0} - $2))
  ((${d#-} * 20 <= $2))
}

OUT="build/benchmark/device/$SESSION"
mkdir -p "$OUT"

# 按 --only / --hz / --backend 过滤后再交给 plan, plan 只核对选中的设备是否在线; 字段数不对的行原样交给 plan 报错。
awk -v hz="$HZ" -v only=",$ONLY," -v backend="$BACKEND" '
  { sub(/#.*/, "") }
  NF && (NF != 4 || ((only == ",," || index(only, "," $1 ",")) && (hz == "" || $3 == hz) && (backend == "all" || $4 == backend)))
' "$CONF" >"$OUT/devices.conf"
[[ -s "$OUT/devices.conf" ]] || bench_die "no devices match --only='$ONLY' --hz='$HZ' --backend='$BACKEND'"

PLAN="$(bench_dart plan "$OUT/devices.conf")"
echo "plan (label id hz backend platform):" >&2
sed 's/^/  /' <<<"$PLAN" >&2

multi="$(awk '{ print $1, $3 }' <<<"$PLAN" | sort -u | awk '{ n[$1]++ } END { for (l in n) if (n[l] > 1) print l }')"
[[ -z "$multi" ]] || bench_die "multiple refresh rates for: $multi; pass --hz to pick one"

mismatch=""
while read -r label id hz _ platform; do
  [[ "$platform" == android ]] || continue
  actual="$(display_hz "$id")"
  if [[ -z "$actual" ]]; then
    mismatch+="  $label: cannot read display refresh rate"$'\n'
  elif ! hz_ok "$actual" "$hz"; then
    mismatch+="  $label: display ${actual}Hz, expected ${hz}Hz"$'\n'
  fi
done <<<"$PLAN"
[[ -z "$mismatch" ]] || { printf 'refresh rate mismatch; set 屏幕刷新率 and rerun the same command:\n%s' "$mismatch" >&2; exit 1; }

# 电量: Android 用 adb 读; iOS 没有免装工具可读, 只提醒。
for id in $(awk '$5 == "android" { print $2 }' <<<"$PLAN" | sort -u); do
  level="$(adb -s "$id" shell dumpsys battery | sed -n 's/^ *level: *//p' | tr -d '\r')"
  [[ "${level:-0}" -ge 50 ]] || echo "warning: $id battery ${level:-?}% (< 50%)" >&2
done
echo "reminder: keep iOS devices above 50% battery, unplugged from power where possible, brightness fixed" >&2

# 构建: 每个版本 × 每个平台一次, 之后所有运行都装这个包。两个版本在各自的树里, 并行构建;
# 同一棵树里的平台依次构建: 它们共用 .dart_tool 与 pub 解析, 并行会互相覆盖。
# 基线按相反的平台顺序构建, 尽量让两条链上的 Gradle 与 Xcode 错开, 少同时起两个 Gradle 抢内存。
build_side() {
  local side="$1" ref=HEAD order=-u platform bin
  [[ "$side" == baseline ]] && ref="$BASELINE" order=-ur
  for platform in $(awk '{ print $5 }' <<<"$PLAN" | sort "$order"); do
    bin="$(tool/benchmark/build.sh --platform "$platform" --ref "$ref" --windows "$WINDOWS" \
      --window-seconds "$WINDOW_SECONDS" "${DIRTY_ARG[@]+"${DIRTY_ARG[@]}"}")" || return
    echo "$platform $bin"
  done >"$OUT/bins-$side"
}

pids=()
for side in "${SIDES[@]}"; do
  echo "building $side, log $OUT/build-$side.log" >&2
  build_side "$side" 2>"$OUT/build-$side.log" &
  pids+=($!)
done
failed=""
for i in "${!pids[@]}"; do
  wait "${pids[$i]}" || failed+=" ${SIDES[$i]}"
done
for side in $failed; do tail -20 "$OUT/build-$side.log" >&2; done
[[ -z "$failed" ]] || bench_die "build failed for:$failed; see $OUT/build-<side>.log"
# BIN_<side>_<platform> 记包路径。
for side in "${SIDES[@]}"; do
  while read -r platform bin; do
    printf -v "BIN_${side}_$platform" '%s' "$bin"
  done <"$OUT/bins-$side"
done

# 每次调用一份失败清单和补采脚本: 同一 session 的多次调用(60Hz、120Hz、补采)互不覆盖。
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
FAILURES="$OUT/failures-$STAMP"
RETRY="$OUT/retry-$STAMP.sh"

# Android 电池温度, 单位 0.1°C; 读不到时为空。
battery_temp() {
  adb -s "$1" shell dumpsys battery </dev/null 2>/dev/null | sed -n 's/^ *temperature: *\([0-9][0-9]*\).*/\1/p' | head -1
}

# 两次运行之间的冷却, 打印实际等待秒数。Android 每 10s 读一次电池温度, 回到这台设备开跑时 +1°C 以内就结束,
# 至少 10s、最多 --cooldown 秒; 开跑温度没读到时等满。iOS 读不到温度, 固定等 60s(不超过 --cooldown)。
cooldown() {
  local id="$1" platform="$2" start_temp="$3" waited=0 t
  if [[ "$platform" != android ]]; then
    waited=$((COOLDOWN < 60 ? COOLDOWN : 60))
    sleep "$waited"
  else
    while ((waited < COOLDOWN)); do
      sleep 10
      waited=$((waited + 10))
      t="$(battery_temp "$id")"
      [[ -n "$start_temp" && -n "$t" ]] && ((t <= start_temp + 10)) && break
    done
  fi
  echo "$waited"
}

# 一台设备的全部运行, 后台执行。掉线或刷新率被改后不再运行, 剩下的运行都记失败, 补采脚本据此算轮数。
run_device() {
  local label="$1" r side bin skip="" first=true start_temp=""
  local log="$OUT/$label.log"
  for ((r = 1; r <= ROUNDS; r++)); do
    for side in "${SIDES[@]}"; do
      while read -r _ id hz backend platform; do
        if [[ -z "$skip" ]]; then
          if $first; then
            first=false
            # 开跑温度只在第一次运行前读一次; 读不到时 cooldown 等满 --cooldown。
            [[ "$platform" != android ]] || start_temp="$(battery_temp "$id")"
          else
            echo "[$(date +%H:%M:%S)] $label cooled down $(cooldown "$id" "$platform" "$start_temp")s" >>"$log"
          fi
          if ! wait_online "$id"; then
            skip=offline
          elif [[ "$platform" == android ]] && ! hz_ok "$(display_hz "$id")" "$hz"; then
            skip=hz-mismatch
          fi
          [[ -z "$skip" ]] || echo "[$(date +%H:%M:%S)] $label $skip, skipping remaining runs" >>"$log"
        fi
        bin="BIN_${side}_$platform"
        if [[ -z "$skip" ]] && tool/benchmark/device.sh --device "$id" --hz "$hz" --side "$side" --backend "$backend" \
          --label "$label" --session "$SESSION" --binary "${!bin}" </dev/null >>"$log" 2>&1; then
          continue
        fi
        echo "$label ${hz}Hz $backend $side round $r  ${skip:-drive-failed}" >>"$FAILURES"
      done < <(awk -v l="$label" '$1 == l' <<<"$PLAN")
    done
  done
}

pids=()
for label in $(awk '{ print $1 }' <<<"$PLAN" | sort -u); do
  echo "$label started, log $OUT/$label.log" >&2
  run_device "$label" &
  pids+=($!)
  # 错开启动: 几个 flutter drive 同时解析同一个工程时会争用 .dart_tool。
  sleep 20
done
wait "${pids[@]}" || true

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

[[ -f "$FAILURES" ]] || exit 0
echo "failed runs (see $OUT/<label>.log):" >&2
sed 's/^/  /' "$FAILURES" >&2
# 补采按 label + hz + backend 合并: 只一侧失败时带 --side, 轮数取失败次数;
# 窗口参数决定构建出的包, 必须和原调用一致, 所以原样带上。
common="--session $SESSION --devices $CONF --baseline $BASELINE --windows $WINDOWS"
common+=" --window-seconds $WINDOW_SECONDS --cooldown $COOLDOWN"
$PUBLISH && common+=" --publish"
[[ ${#DIRTY_ARG[@]} -eq 0 ]] || common+=" --allow-dirty"
{
  printf '#!/usr/bin/env bash\n# 补采 session %s 调用 %s 的失败项; 先确认设备在线、刷新率已设好。\n' "$SESSION" "$STAMP"
  printf 'set -euo pipefail\ncd "$(dirname "$0")/../../../.."\n'
  awk -v common="$common" '
    { sub(/Hz$/, "", $2); key = $1 " " $2 " " $3; keys[key] = 1; n[key, $4]++ }
    END {
      for (k in keys) {
        split(k, p, " ")
        b = n[k, "baseline"] + 0; t = n[k, "target"] + 0
        side = b == 0 ? " --side target" : t == 0 ? " --side baseline" : ""
        print "tool/benchmark/matrix.sh " common " --only " p[1] " --hz " p[2] " --backend " p[3] side " --rounds " (b > t ? b : t)
      }
    }
  ' "$FAILURES" | sort
} >"$RETRY"
chmod +x "$RETRY"
echo "retry commands (also in $RETRY):" >&2
grep '^tool/' "$RETRY" | sed 's/^/  /' >&2
exit 1

#!/usr/bin/env bash
# 删掉 benchmark 脚本创建的基线 / 目标 worktree(.worktrees/benchmark/ 下的 baseline、target)并清理失效登记。
#
#   tool/benchmark/clean.sh
#
# 只处理这两个固定名字, 不碰 .worktrees/ 下的开发 worktree; 下次运行时脚本会自动重建。
# 构建好的包(build/benchmark/bin/)和采集结果(build/benchmark/device/)不在这里, 不受影响。
set -euo pipefail
source "$(dirname "$0")/lib.sh"

for role in baseline target; do
  tree="$BENCH_WT/$role"
  [[ ! -e "$tree" ]] || echo "removing $tree" >&2
  bench_drop_tree "$tree"
done

# shellcheck shell=bash
# benchmark 脚本的公共函数, 由各脚本 source; 只做进程编排, JSON / 配置的读写交给 bench.dart。
#
# 约定: sed / awk 只用 POSIX 写法(字符类用 [[:space:]], 不用 \s, 不用 sed -i), macOS 与 Linux 行为一致。

BENCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BENCH_DIR="$BENCH_ROOT/tool/benchmark"

# 基线 / 非 HEAD 目标的 worktree 放在 build/ 之外, `flutter clean` 不会删除它们。
BENCH_WT="$BENCH_ROOT/.worktrees/benchmark"

bench_die() {
  echo "$*" >&2
  exit 64
}

bench_dart() {
  fvm dart "$BENCH_DIR/bench.dart" "$@"
}

# 结果要记被测代码的 sha: 工作区有未提交改动时拒绝运行; 传 true 放行并把 DIRTY 设为 -dirty。
# 已跟踪文件的改动都算; 未跟踪文件只看会被编进包或覆盖进基线树的目录, 其他地方的草稿文件不拦。
bench_require_clean() {
  DIRTY=""
  if [[ -z "$(git -C "$BENCH_ROOT" status --porcelain --untracked-files=no)" &&
    -z "$(git -C "$BENCH_ROOT" ls-files --others --exclude-standard -- apps/benchmark packages tool/benchmark)" ]]; then
    return
  fi
  [[ "$1" == true ]] || { echo "working tree has uncommitted changes; commit first or pass --allow-dirty" >&2; exit 1; }
  DIRTY="-dirty"
}

# 10 位 sha; ref 指向 HEAD 且工作区不干净时带 -dirty(需先调 bench_require_clean)。
bench_sha() {
  local sha
  sha="$(git -C "$BENCH_ROOT" rev-parse --short=10 "$1^{commit}")"
  [[ "$(git -C "$BENCH_ROOT" rev-parse "$1^{commit}")" == "$(git -C "$BENCH_ROOT" rev-parse HEAD)" ]] && sha="$sha${DIRTY:-}"
  echo "$sha"
}

# 覆盖进别的版本的基准代码(app、L1 场景与 harness、.fvmrc)的指纹, 取当前 HEAD 提交的内容。
# 它和 sha 一起决定基线包能否复用: 基线包里真正决定场景行为的是覆盖进去的当前代码, 不是基线自己的 sha。
bench_code_id() {
  git -C "$BENCH_ROOT" rev-parse HEAD:apps/benchmark HEAD:packages/flexi_kline/test/benchmark/versioned \
    HEAD:packages/flexi_kline/test/support/benchmark/bench_harness.dart HEAD:.fvmrc | git hash-object --stdin | cut -c1-10
}

# bench_tree <ref> <role> [overlay.sh 参数]: 把 ref 解析成可运行的树并写入 TREE。
# - ref 就是 HEAD 时用当前树;
# - 否则用 $BENCH_WT/<role>(role 为 baseline 或 target, 最多两个固定名字, 不随版本累积):
#   已有且 HEAD 就是 ref 时复用, 否则(不存在、损坏、版本不对)移除后重建;
#   再把当前的基准代码覆盖进去(overlay.sh 幂等, 内容没变就跳过)。
# 不用 $(...) 返回: 调用方要在同一个 shell 里拿到 TREE。清理用 tool/benchmark/clean.sh。
bench_tree() {
  local ref="$1" role="$2" sha
  shift 2
  [[ "$role" == baseline || "$role" == target ]] || bench_die "bench_tree: role must be baseline or target"
  sha="$(git -C "$BENCH_ROOT" rev-parse "$ref^{commit}")"
  if [[ "$sha" == "$(git -C "$BENCH_ROOT" rev-parse HEAD)" ]]; then
    TREE="$BENCH_ROOT"
    return
  fi
  TREE="$BENCH_WT/$role"
  if [[ ! -e "$TREE/.git" || "$(git -C "$TREE" rev-parse HEAD 2>/dev/null)" != "$sha" ]]; then
    bench_drop_tree "$TREE"
    git -C "$BENCH_ROOT" worktree add --detach "$TREE" "$sha" >/dev/null
  fi
  "$BENCH_DIR/overlay.sh" "$TREE" "$@"
}

# 移除 $1 处的 worktree(不存在时只清登记)。残留目录可能已不是登记在册的 worktree(remove 会失败), 此时直接删目录;
# 之后 prune 清掉失效登记, 否则同名 add 会另起 <名>1 的登记。
bench_drop_tree() {
  [[ ! -e "$1" ]] || git -C "$BENCH_ROOT" worktree remove --force "$1" 2>/dev/null || rm -rf "$1"
  git -C "$BENCH_ROOT" worktree prune
}

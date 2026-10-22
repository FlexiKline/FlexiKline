# shellcheck shell=bash
# benchmark 脚本的公共函数, 由各脚本 source; 只做进程编排, JSON / 配置的读写交给 bench.dart。
#
# 约定: sed / awk 只用 POSIX 写法(字符类用 [[:space:]], 不用 \s, 不用 sed -i), macOS 与 Linux 行为一致。

BENCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BENCH_DIR="$BENCH_ROOT/tool/benchmark"

bench_die() {
  echo "$*" >&2
  exit 64
}

bench_dart() {
  fvm dart "$BENCH_DIR/bench.dart" "$@"
}

# 结果要记被测代码的 sha: 工作区有未提交改动时拒绝运行; 传 true 放行并把 DIRTY 设为 -dirty。
bench_require_clean() {
  DIRTY=""
  [[ -z "$(git -C "$BENCH_ROOT" status --porcelain --untracked-files=no)" ]] && return
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

# 把 ref 解析成可运行的树并写入 TREE: 就是 HEAD 时用当前树, 否则复用或新建 build/benchmark/wt/<sha>,
# 再把当前的基准代码覆盖进去(overlay.sh 幂等)。worktree 按 sha 缓存, 不自动删除:
# 清理用 `git worktree remove --force build/benchmark/wt/<sha>`。
# 不用 $(...) 返回: 调用方要在同一个 shell 里拿到 TREE。
bench_tree() {
  local ref="$1" sha
  shift
  sha="$(git -C "$BENCH_ROOT" rev-parse "$ref^{commit}")"
  if [[ "$sha" == "$(git -C "$BENCH_ROOT" rev-parse HEAD)" ]]; then
    TREE="$BENCH_ROOT"
    return
  fi
  TREE="$BENCH_ROOT/build/benchmark/wt/${sha:0:10}"
  [[ -d "$TREE" ]] || git -C "$BENCH_ROOT" worktree add --detach "$TREE" "$sha" >/dev/null
  "$BENCH_DIR/overlay.sh" "$TREE" "$@"
}

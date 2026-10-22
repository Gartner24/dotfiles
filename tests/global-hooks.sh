#!/usr/bin/env bash
# The global git hooks (home/git/.config/git/hooks) refuse a Claude attribution line in any
# repo and still run each repo's own hooks. Throwaway repos and HOME; touches nothing real.
# Run: tests/global-hooks.sh
set -uo pipefail

SRC=$(dirname "$(readlink -f "$0")")/..
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
export HOME=$T/home GIT_CONFIG_GLOBAL=$T/gitconfig GIT_CONFIG_NOSYSTEM=1
mkdir -p "$HOME/.config/git"
# as dot install leaves it: the hooks folder under ~, and the hooksPath line the repo ships
ln -s "$SRC/home/git/.config/git/hooks" "$HOME/.config/git/hooks"
git config --global user.name test
git config --global user.email test@example.com
git config --global init.defaultBranch main
git config --global core.hooksPath "$(git config -f "$SRC/home/git/.gitconfig" core.hooksPath)"
fail=0

# Banned phrases are built from two halves, so no file in a repo holds the whole phrase.
TRAILER="Co-Authored-""By: Claude Opus 4.8 (1M context) <noreply@""anthropic.com>"
GENERATED="Generated with [Claude ""Code](https://claude.com/claude-code)"
SESSION="Claude-Session: https://claude.ai/code/""session_011abc"

commit() { # name, expect ok|refused, git commit args...
  local name=$1 want=$2 out rc got; shift 2
  out=$(git commit -q --allow-empty "$@" 2>&1); rc=$?
  got=ok; ((rc)) && got=refused
  if [[ $got == "$want" ]]; then echo "ok   $name"
  else echo "FAIL $name (wanted $want, got $got)"; echo "$out" | sed 's/^/  /'; fail=1
  fi
}

git init -q "$T/a"
cd "$T/a" || exit 1
commit "clean commit passes" ok -m "feat: clean"
commit "Co-Authored-By trailer refused" refused -m "feat: x" -m "$TRAILER"
commit "lower case trailer refused" refused -m "feat: x" -m "${TRAILER,,}"
commit "Generated with line refused" refused -m "feat: x" -m "$GENERATED"
commit "session link refused" refused -m "feat: x" -m "$SESSION"
commit "human co-author passes" ok -m "feat: x" -m "Co-Authored-""By: Ana <ana@example.com>"
# commit -v puts the staged diff under a scissors line; a diff quoting the trailer is not the message
printf '%s\n' "$TRAILER" >quoted && git add quoted
GIT_EDITOR=true commit "trailer only in the commit -v diff passes" ok -v -e -m "docs: quote it"
GIT_EDITOR=true commit "trailer above the scissors refused" refused -v -e -m "feat: x" -m "$TRAILER"

# the repo's own hooks still run, see the same args, and can still refuse
cat >.git/hooks/commit-msg <<'EOF'
#!/bin/sh
echo "$1" >"$(git rev-parse --git-common-dir)/ran-commit-msg"
! grep -q BAD "$1"
EOF
cat >.git/hooks/pre-commit <<'EOF'
#!/bin/sh
touch "$(git rev-parse --git-common-dir)/ran-pre-commit"
[ ! -e block-pre-commit ]
EOF
chmod +x .git/hooks/commit-msg .git/hooks/pre-commit
commit "clean commit passes with repo hooks" ok -m "feat: hooks"
if [[ -s .git/ran-commit-msg && -e .git/ran-pre-commit ]]; then echo "ok   repo commit-msg and pre-commit ran"
else echo "FAIL repo commit-msg or pre-commit did not run"; fail=1
fi
commit "repo commit-msg can still refuse" refused -m "feat: BAD"
touch block-pre-commit
commit "repo pre-commit can still refuse" refused -m "feat: blocked"
rm block-pre-commit
commit "trailer refused with repo hooks present" refused -m "feat: x" -m "$TRAILER"

rm .git/ran-pre-commit
git worktree add -q "$T/a-wt" 2>/dev/null
cd "$T/a-wt" || exit 1
commit "repo hooks run in a linked worktree" ok -m "feat: wt"
if [[ -e $T/a/.git/ran-pre-commit ]]; then echo "ok   repo pre-commit ran from the worktree"
else echo "FAIL repo pre-commit did not run from the worktree"; fail=1
fi

# a repo with its own core.hooksPath ignores the global one: dotfiles links hooks/commit-msg
git init -q "$T/b"
cd "$T/b" || exit 1
mkdir hooks
ln -s "$SRC/hooks/commit-msg" hooks/commit-msg
git config core.hooksPath hooks
commit "local hooksPath: clean commit passes" ok -m "feat: clean"
commit "local hooksPath: trailer refused" refused -m "feat: x" -m "$TRAILER"

exit $fail

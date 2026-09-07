#!/bin/sh
set -eu
cd -- "$(dirname "$0")"
. ./test.sh
formatter=$(cd ../bin && pwd)/fmt.sh
cd - >/dev/null

case_d2_formatter() {
  directory=$(mktempd)
  mkdir "$directory/bin" "$directory/repo"
  cat >"$directory/bin/d2" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"$FORMATTER_CALLS"
exit "${FORMATTER_STATUS:-0}"
EOF
  chmod +x "$directory/bin/d2"
  PATH="$directory/bin:$PATH"
  export PATH FORMATTER_CALLS="$directory/calls"
  # Match git's physical root path (macOS temporary directories use a symlink).
  cd -P "$directory/repo"
  git_pure init -q
  printf 'a -> b\n' >fixture.d2
  printf 'unchanged\n' >unchanged.d2
  git_pure add .
  git_pure -c commit.gpgsign=false commit -qm fixture
  export CI=1 GIT_BASE=HEAD OS=linux
  printf 'a->b\n' >fixture.d2

  "$formatter"
  assert calls "$(cat "$FORMATTER_CALLS")" 'fmt fixture.d2'
  export FORMATTER_STATUS=23
  if "$formatter"; then
    echoerr "formatter failure was ignored"
    return 1
  fi
}

job_parseflags "$@"
runjob case_d2_formatter

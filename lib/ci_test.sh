#!/bin/sh
set -eu
cd -- "$(dirname "$0")"
. ./test.sh
. ./ci.sh
cd - >/dev/null

case_commit_wording() {
  CI=1
  CI_MAKE_ROOT=0
  GIT_BASE=
  cd "$(mktempd)"
  git_pure init -q
  printf 'tracked\n' >file
  git_pure add file
  git_pure -c commit.gpgsign=false commit -qm 'fixup! permitted by caller'
  ci_waitjobs
  # The opt-in standalone check still works.
  if nofixups; then
    echoerr "standalone nofixups check should reject the fixture"
    return 1
  fi
  printf 'dirty\n' >>file
  if ci_waitjobs; then
    echoerr "CI cleanup accepted a dirty tracked file"
    return 1
  fi
}

case_local_failure() {
  CI=
  runjob_bg failing false
  if ci_waitjobs; then
    echoerr "local cleanup accepted a failed background job"
    return 1
  fi
}

case_notification_status() {
  CI=1
  CI_MAKE_ROOT=1
  GITHUB_REF_PROTECTED=true
  GITHUB_RUN_ID=1
  GITHUB_JOB=test
  GITHUB_REPOSITORY=test/repo
  GITHUB_WORKFLOW=test
  GITHUB_TOKEN=test
  DISCORD_WEBHOOK_URL=https://example.invalid/webhook
  nofixups() { echoerr "notification invoked nofixups"; return 1; }
  curl() {
    case "$*" in
      *' -X POST '*) return 0 ;;
      *) printf '%s\n' '{"jobs":[{"name":"test","html_url":"https://example.invalid/job"}]}' ;;
    esac
  }
  code=0
  notify
  assert code 0
}

job_parseflags "$@"
runjob case_commit_wording
runjob case_local_failure
runjob case_notification_status

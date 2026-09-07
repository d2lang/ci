#!/bin/sh
set -eu
cd -- "$(dirname "$0")"
. ./test.sh
cd - >/dev/null

# Synchronize on completion without consuming the status that waitjobs must keep.
await_completed() {
  test_attempt=0
  while kill -0 "$1" 2>/dev/null; do
    test_attempt=$((test_attempt + 1))
    if [ "$test_attempt" -ge 500 ]; then
      echoerr "job $1 did not finish within five seconds"
      return 1
    fi
    sleep 0.01
  done
}

await_file() {
  test_attempt=0
  while [ ! -f "$1" ]; do
    test_attempt=$((test_attempt + 1))
    if [ "$test_attempt" -ge 500 ]; then
      echoerr "job did not produce $1 within five seconds"
      return 1
    fi
    sleep 0.01
  done
}

expect_failed_batch() {
  if waitjobs; then
    echoerr "waitjobs accepted a failed job"
    return 1
  fi
}

case_completed_success() {
  runjob_bg success true
  await_completed "$!"
  waitjobs
}

case_completed_failure() {
  runjob_bg failure false
  await_completed "$!"
  expect_failed_batch
}

case_mixed_after_jobs() {
  runjob_bg success true
  success_pid=$!
  runjob_bg failure false
  failure_pid=$!
  await_completed "$success_pid"
  await_completed "$failure_pid"
  # Listing completed jobs can discard the shell's jobs-table entries.
  jobs -l >/dev/null
  expect_failed_batch
}

case_batch_reset() {
  runjob_bg failure false
  expect_failed_batch
  waitjobs
  runjob_bg success true
  waitjobs
  waitjobs
}

case_nested() {
  nested_dir=$(mktempd)
  unrelated() {
    await_file "$nested_dir/release"
    touch "$nested_dir/unrelated-done"
  }
  nested_success() {
    runjob_bg leaf true
    waitjobs
    touch "$nested_dir/nested-success"
  }
  nested_failure() {
    runjob_bg leaf false
    waitjobs
  }

  runjob_bg unrelated unrelated
  runjob_bg nested-success nested_success
  success_pid=$!
  runjob_bg nested-failure nested_failure
  failure_pid=$!
  await_file "$nested_dir/nested-success"
  await_completed "$success_pid"
  await_completed "$failure_pid"
  test ! -f "$nested_dir/unrelated-done"
  touch "$nested_dir/release"
  expect_failed_batch
  test -f "$nested_dir/unrelated-done"
}

case_unregistered() {
  legacy_output=$(mktempd)/error
  # Reject visible legacy launches even when their command succeeds.
  runjob legacy 'sleep 0.1; true' >/dev/null 2>&1 &
  if waitjobs 2>"$legacy_output"; then
    echoerr "waitjobs accepted an unregistered background job"
    return 1
  fi
  grep -q 'unregistered background job .*use runjob_bg' "$legacy_output"
}

case_terminated() {
  term_dir=$(mktempd)
  stoppable() {
    touch "$term_dir/ready"
    # Remain bounded even if the wrapper leaves its command running on TERM.
    sleep 0.2
  }
  runjob_bg stopped stoppable
  stopped_pid=$!
  await_file "$term_dir/ready"
  kill -TERM "$stopped_pid"
  expect_failed_batch
  await_completed "$stopped_pid"
  # The existing wrapper can leave its command alive briefly after cancellation.
  sleep 0.3
}

job_parseflags "$@"
runjob case_completed_success
runjob case_completed_failure
runjob case_mixed_after_jobs
runjob case_batch_reset
runjob case_nested
runjob case_unregistered
runjob case_terminated

#!/bin/sh
set -eu
cd -- "$(dirname "$0")/.."
cd ./lib
. ./job.sh
. ./git.sh
cd - >/dev/null

job_parseflags "$@"
if is_changed ./lib/test.sh ./lib/rand.sh ./lib/log.sh \
  ./lib/temp.sh; then
  runjob_bg log ./lib/log_test.sh
fi
if is_changed ./lib/test.sh ./lib/rand.sh ./lib/log.sh \
  ./lib/flag.sh ./lib/temp.sh; then
  runjob_bg flag ./lib/flag_test.sh
fi
if is_changed \
  ./lib/test.sh ./lib/rand.sh ./lib/log.sh ./lib/git.sh \
  ./lib/flag.sh ./lib/ci.sh ./lib/job.sh ./lib/notify.sh \
  ./lib/temp.sh ./lib/release.sh; then
  runjob_bg make ./lib/make_test.sh
fi
if is_changed ./lib/job.sh ./lib/job_test.sh ./lib/ci.sh ./lib/ci_test.sh \
  ./lib/notify.sh ./lib/log.sh ./lib/test.sh ./lib/temp.sh ./ci/test.sh; then
  runjob_bg job ./lib/job_test.sh
  runjob_bg ci ./lib/ci_test.sh
fi
if is_changed ./bin/fmt.sh ./lib/fmt_test.sh ./lib/git.sh ./lib/job.sh \
  ./lib/log.sh ./lib/test.sh ./lib/temp.sh ./ci/test.sh; then
  runjob_bg formatter ./lib/fmt_test.sh
fi
waitjobs

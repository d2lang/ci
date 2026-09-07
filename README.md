# ci

[![ci](https://github.com/d2lang/ci/actions/workflows/ci.yml/badge.svg)](https://github.com/d2lang/ci/actions/workflows/ci.yml)
[![daily](https://github.com/d2lang/ci/actions/workflows/daily.yml/badge.svg)](https://github.com/d2lang/ci/actions/workflows/daily.yml)
[![license](https://img.shields.io/github/license/d2lang/ci?color=9cf)](./LICENSE)

Shared CI scripts for D2 and related projects.

Currently used by:

- https://github.com/d2lang/d2
- https://github.com/d2lang/d2-docs
- https://github.com/d2lang/util-go
- https://github.com/d2lang/text-to-diagram-site
- https://github.com/terrastruct/byelinear
- https://github.com/terrastruct/homebrew-tap
- https://github.com/d2lang/d2-obsidian
- https://github.com/d2lang/d2-playground
- https://github.com/d2lang/d2-vscode

And in our internal monorepo.

For robust example usage of the flag parser see [./examples/date.sh](./examples/date.sh).

Use `runjob name command` for foreground work. For parallel work, replace
`runjob name command &` with `runjob_bg name command`, then call `waitjobs`.
The launcher records each process ID immediately so completed failures cannot be
lost from the shell's job list. `waitjobs` rejects unregistered background jobs
that it can still detect; migrate callers before updating this shared library.

`ci_waitjobs` waits for jobs and checks generated files. Commit-message policy is
opt-in through `bin/nofixups.sh`; cleanup and notifications do not enforce it.

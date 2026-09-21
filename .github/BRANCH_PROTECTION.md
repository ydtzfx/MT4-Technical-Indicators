# Required status check policy

The stable merge-blocking check produced by this repository is:

`P0.5 / Required Gate`

The check passes only when:

- the immutable compiler and Wine image digests match `Tools/ci/mt4-compiler.lock.json`;
- exactly 201 production `.mq4` files are discovered;
- all 201 compile successfully with 0 compiler errors;
- the compile-log parser has 0 failures;
- the no-repaint probe itself compiles 1/1 with 0 errors;
- production and probe jobs use the same MetaEditor binary SHA256.

Warnings are reported in the artifact but are not a P0 merge blocker.

Repository administration must require `P0.5 / Required Gate` on `master`. The GitHub connector used to create this file has no branch-protection write permission, so that final repository setting must be enabled by an administrator in GitHub Settings.

The workflow uploads two 30-day evidence artifacts per run:

- `p0-5-compile-report-<sha>`
- `p0-5-probe-report-<sha>`

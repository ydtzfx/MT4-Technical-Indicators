# Required status check policy

The stable merge-blocking check produced by this repository is:

`P0.5 / Required Gate`

The check passes only when the programmatic verifier confirms:

- static P0 correctness rules pass;
- the immutable compiler and Wine image digests match `Tools/ci/mt4-compiler.lock.json`;
- exactly 201 production `.mq4` files are discovered;
- all 201 compile successfully with 0 compiler errors;
- the compile-log parser has 0 failures;
- the no-repaint probe compiles 1/1 with 0 errors;
- production and probe jobs use the same MetaEditor binary SHA256.

Warnings are reported in the artifact but are not a P0 merge blocker.

Runtime no-repaint evidence is evaluated by:

`python Tools/ci/p05_verify.py runtime`

and the final >=95% engineering-confidence decision is evaluated by:

`python Tools/ci/p05_verify.py release-gate`

Repository administration must require `P0.5 / Required Gate` on `master`. The GitHub connector used here has no branch-protection write permission, so that repository setting must be enabled by an administrator in GitHub Settings.

Evidence artifacts are retained for 30 days.

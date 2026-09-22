# P0.5 Programmatic Verification

Single source of truth: `Tools/ci/p05_verify.py`.

## Commands

Static correctness and repository invariants:

```bash
python Tools/ci/p05_verify.py static --root . --out artifacts/p0-5/static
```

Validate locked MetaEditor compile/probe reports plus static report:

```bash
python Tools/ci/p05_verify.py ci-gate \
  --compile gate/compile \
  --probe gate/probe \
  --static gate/static \
  --lock Tools/ci/mt4-compiler.lock.json \
  --out gate/final
```

Validate Strategy Tester closed-bar persistence evidence:

```bash
python Tools/ci/p05_verify.py runtime \
  --csv p0_5_no_repaint.csv \
  --out artifacts/p0-5/runtime
```

Default runtime acceptance threshold:

- at least 20 bar transitions;
- 23 channels;
- 8 closed bars per transition;
- at least 3,680 comparisons;
- 0 repaint violations;
- one-sided 95% violation-rate upper bound below 0.1%.

Combine CI + runtime evidence for the final engineering-confidence gate:

```bash
python Tools/ci/p05_verify.py release-gate \
  --ci artifacts/p0-5/ci \
  --runtime artifacts/p0-5/runtime \
  --out artifacts/p0-5/release
```

The release gate is the programmatic definition of the requested >=95% engineering-confidence target. It is not a mathematical proof that repainting is impossible; it is an auditable threshold backed by compiler, static, and runtime evidence.

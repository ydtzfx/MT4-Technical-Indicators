# GEMINI.md

This file provides guidance to Gemini CLI when working with this repository.

## Overview

This is a complete set of MetaTrader 4 (MT4) technical indicators written in MQL4, with a strict **no future function** (无未来函数) design. All buy/sell signals are generated exclusively from **completed bars** (bar index ≥ 1) and never repaint.

**212 files** across 7 directories: 201 indicator files (`.mq4`), 4 shared headers (`.mqh`), 1 CLAUDE.md, 1 GEMINI.md, 1 README, plus automation config in `.claude/` and design docs in `docs/`.

## Architecture

### Header Dependency Chain
```
Common.mqh          ← fundamental constants, enums, MA calculation, safe division
  ↓
PriceData.mqh       ← depends on Common.mqh; safe price data access, True Range, DM
  ↓
SignalBase.mqh      ← depends on Common.mqh; signal buffer pattern, cross detection, OB/OS
  ↓
Drawing.mqh         ← depends on Common.mqh; arrows, lines, labels, object cleanup
```

### Core Design Rule: No Future Function

```
Signals (bar ≥ 1)  → permanent, never modified, never repaints
Display (bar = 0)  → refreshed every tick, does NOT generate signals
```

## Automation

### Git Hooks (`hooks/` → `.git/hooks/`)
- `pre-commit`: Validates staged `.mq4` files — blocks on CRITICAL violations (bar[0] signal, buffer count mismatch)
- `pre-push`: Quick full scan with warnings only (never blocks push)

### Gemini CLI Automation (`.claude/` compatible)
- `settings.json`: PostToolUse multi-rule validation, SessionStart project summary, PreCompact state snapshot
- `agents/mql4-reviewer.md`: Comprehensive MQL4 code reviewer (8 dimensions)
- `skills/mql4-validate/SKILL.md`: 6-rule automated validator

### Gemini CLI Tool Mapping

When using Gemini CLI, these are the tool equivalents for project skills:

| Skill Reference | Gemini CLI Equivalent |
|-----------------|----------------------|
| `Read` | `read_file` |
| `Write` | `write_file` |
| `Edit` | `replace` |
| `Bash` | `run_shell_command` |
| `Grep` | `grep_search` |
| `Glob` | `glob` |
| `TodoWrite` | `write_todos` |
| `Skill` | `activate_skill` |
| Agent dispatch | `@generalist` with prompt |

### Gemini CLI Subagent Dispatch

When a skill says to use a subagent, use `@generalist`:
- Review code → `@generalist` with mql4-reviewer prompt
- Validate indicators → `@generalist` with mql4-validate rules
- Explore codebase → `@generalist` with exploration context

## Quick Validation (Static Analysis)

Use these grep patterns to catch common no-future-function violations:
```bash
# Find bar[0] signal assignments (should only be EMPTY_VALUE in signal buffers)
grep_search "signal.*\[0\].*=" --include="*.mq4" . | grep -v EMPTY_VALUE

# Verify IndicatorCounted usage in all indicators
grep_search "IndicatorCounted" --include="*.mq4" .

# Count buffers declared vs. SetIndexBuffer calls per file
grep_search "indicator_buffers" --include="*.mq4" .
```

## MQL4 Gotchas

- **UTF-8 BOM required**: MT4 compiler requires UTF-8 with BOM encoding. Files without BOM will fail to compile.
- **`#property strict`**: Not used in this project for MT4 backward compatibility.
- **Buffer indexing**: `SetIndexBuffer` indices are 0-based and must match declaration order.
- **`Bars` count**: On first load `IndicatorCounted()` returns 0, so `limit = Bars - InpPeriod*3` prevents accessing non-existent history.
- **`EMPTY_VALUE`**: Use for unfilled signal buffer slots. MT4 skips drawing at EMPTY_VALUE positions.
- **Bar 0 volatility**: `iClose(_Symbol, _Period, 0)` changes every tick. Never use it for signal logic.

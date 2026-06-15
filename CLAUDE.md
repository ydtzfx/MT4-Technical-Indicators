# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

A complete set of 201 MetaTrader 4 (MT4) technical indicators written in MQL4, all compiling with **0 errors** on MT4 Build 600+. Strict **no future function** (无未来函数) design — buy/sell signals are generated exclusively from completed bars (index ≥ 1) and never repaint.

```
201 indicator files (.mq4) + 4 shared headers (.mqh) + install script
6 category directories: Trend(25) / Oscillators(20) / Volume(10) / BillWilliams(5) / Custom(140) / Templates(1)
```

## Architecture

### Header Dependency Chain (order matters)
```
Common.mqh          ← constants, enums (SAFE_PRICE_*), CalculateMA(), SafeDivide(), IsNewBar()
  ↓
PriceData.mqh       ← GetTrueRange(), GetHighestHigh()/GetLowestLow(), FillPriceArray()
  ↓
SignalBase.mqh      ← DetectCross(), SetArrowSignal(), DetectOverboughtOversoldExit()
  ↓
Drawing.mqh         ← RemoveObjectsByPrefix(), DrawBuyArrow(), DrawSellArrow(), DrawTrendLine()
```

Every `.mq4` file must `#include "../Include/Common.mqh"` at minimum.  22 files also include PriceData.mqh (those using GetTrueRange/GetHighestHigh).  8 files also include Drawing.mqh (those using RemoveObjectsByPrefix/DrawBuyArrow).

### No Future Function Pattern

```mql4
int start() {
    int counted_bars = IndicatorCounted();
    int limit = Bars - counted_bars;
    if (limit > Bars - 2) limit = Bars - SAFETY_MARGIN;

    for (int i = limit; i >= 1; i--) {      // Signals: bar ≥ 1 only
        buffer[i] = CalculateValue(i);
        signalBuffer[i] = (condition) ? value : EMPTY_VALUE;
    }
    buffer[0] = CalculateValue(0);           // Display only
    signalBuffer[0] = EMPTY_VALUE;           // NEVER signal on bar[0]
    return(0);
}
```

### Signal Grading Pattern

Many indicators (71/201) use a 3-tier signal strength system with dedicated strong-signal buffers:

```mql4
// Buffer declarations (in order, matching SetIndexBuffer indices):
double buySignal[], sellSignal[];       // Normal signals (arrow width=2, green/red)
double strongBuy[], strongSell[];       // Strong signals (arrow width=4, cyan/deepPink)

// In init():
SetIndexStyle(2, DRAW_ARROW, STYLE_SOLID, 2, clrLime);       // buySignal = index 2
SetIndexArrow(2, 233);                                        // 233 = up arrow
SetIndexStyle(3, DRAW_ARROW, STYLE_SOLID, 2, clrRed);        // sellSignal = index 3
SetIndexArrow(3, 234);                                        // 234 = down arrow
SetIndexStyle(4, DRAW_ARROW, STYLE_SOLID, 4, clrCyan);       // strongBuy = index 4
SetIndexArrow(4, 233);
SetIndexStyle(5, DRAW_ARROW, STYLE_SOLID, 4, clrDeepPink);   // strongSell = index 5
SetIndexArrow(5, 234);
```

Signal strength is determined by multiple confirming conditions:
- **WEAK** (1 condition met) → no arrow (used only for internal state tracking)
- **MEDIUM** (2 conditions met) → normal arrow (buySignal/sellSignal)
- **STRONG** (3+ conditions met) → strong arrow (strongBuy/strongSell)

```mql4
// In start() loop:
int signalStrength = 0;
if (condition1) signalStrength++;
if (condition2) signalStrength++;
if (condition3) signalStrength++;

if (signalStrength >= 2) {
    buySignal[i] = (direction == BUY) ? price : EMPTY_VALUE;
    sellSignal[i] = (direction == SELL) ? price : EMPTY_VALUE;
}
if (signalStrength >= 3) {
    strongBuy[i] = (direction == BUY) ? price : EMPTY_VALUE;
    strongSell[i] = (direction == SELL) ? price : EMPTY_VALUE;
}

// Bar 0: ALL signal buffers set to EMPTY_VALUE
buySignal[0] = EMPTY_VALUE;
sellSignal[0] = EMPTY_VALUE;
strongBuy[0] = EMPTY_VALUE;
strongSell[0] = EMPTY_VALUE;
```

**Rules for strong signal buffers:**
- Must be declared in buffer array and initialized with `EMPTY_VALUE` in `init()`
- Must have `SetIndexStyle` with `DRAW_ARROW` configured (arrow code 233=up, 234=down)
- Strong arrows use width=4 (vs width=2 for normal), colors clrCyan/clrDeepPink
- Signal strength must use at least 2 distinct conditions to qualify as MEDIUM

### `_Safe` Suffix Convention

Every indicator in this project uses the `_Safe` suffix (e.g., `MA_Safe.mq4`, `RSI_Safe.mq4`). This marks the indicator as **future-function-free**: all signals are generated exclusively from completed bars and never repaint. When creating new indicators, always use this suffix.

## Installation

Use the included script to auto-detect MT4 and install:
```powershell
.\install_to_mt4.ps1              # Interactive (detects MT4, confirms, copies)
.\install_to_mt4.ps1 -Force       # Silent install
.\install_to_mt4.ps1 -MT4Path "D:\MT4"  # Specify path
```

Manual install:
1. Copy all `.mq4` files to `<MT4_Data>\MQL4\Indicators\`
2. Copy all `.mqh` files to `<MT4_Data>\MQL4\Include\`
3. Compile in MT4: F4 → open file → F7

## Compilation

MQL4 compilation requires MetaTrader 4. From command line:
```powershell
& "D:\ATFX\metaeditor.exe" /compile:"path\to\indicator.mq4" /log:"path\to\output.log"
```

Check results (logs are UTF-16 LE):
```powershell
$c = [System.IO.File]::ReadAllText("output.log", [System.Text.Encoding]::Unicode)
$c -match "0 error"  # True = success
```

## MQL4 Gotchas

### C89 Function-Scope Variables (CRITICAL)
MQL4 uses C89 scoping rules: variables declared anywhere in a function body (including inside `for` loops and `{ }` blocks) are scoped to the entire function. **Never declare the same variable name twice in the same function.**

```mql4
// WRONG — MQL4 treats both i as same scope:
int start() {
    for (int i = 0; i < 10; i++) { ... }
    for (int i = 5; i < 15; i++) { ... }  // ERROR: 'i' already defined
}

// RIGHT — declare once at function top, reuse:
int start() {
    int i;
    for (i = 0; i < 10; i++) { ... }
    for (i = 5; i < 15; i++) { ... }
}
```

This applies to ALL variable names including `j`, `jj`, `jjj`, `h`, `l`, `c`, `v`, `s`, `atr`, etc. The project uses `ii`, `iii`, `iiii`, `jj`, `jjj`, `jjjj`, `jjjjj`, `jjjjjj`, `jjjjjjj` as distinct names to avoid conflicts across nested loops within the same function.

### No C-Style Pointer Arrays
MQL4 does NOT support `double *arr[] = {buf1, buf2, ...}`. Each buffer must be individually declared and bound with SetIndexBuffer. Files that originally used pointer arrays (GuppyMMA, MTF_RSI, CandlePatternScanner, RainbowMA) have been rewritten with individual buffer declarations.

### Enum Name Conflicts
MQL4 predefines `PRICE_CLOSE`, `PRICE_OPEN`, `PRICE_HIGH`, `PRICE_LOW`, `PRICE_MEDIAN`, `PRICE_TYPICAL`, `PRICE_WEIGHTED` as built-in constants. This project uses `SAFE_PRICE_CLOSE`, `SAFE_PRICE_OPEN`, etc. in `Common.mqh` to avoid conflicts.

### Other Gotchas
- **UTF-8 BOM required**: Files without BOM fail to compile. All files in this repo have BOM.
- **Include path**: `#include "../Include/Common.mqh"` is relative from category subdirectories. Works when project structure is preserved.
- **`#property strict`**: Not used — for MT4 backward compatibility.
- **`EMPTY_VALUE`**: Sentinel for unfilled signal buffer slots. MT4 skips drawing at these positions.
- **Bar 0**: `iClose(_Symbol, _Period, 0)` changes every tick. Never use for signal logic.
- **Buffer index alignment**: `SetIndexBuffer` indices are 0-based and must match the declaration order of buffer arrays. Mismatched order causes MT4 to draw arrows on the wrong buffer or skip them entirely. Always verify: buffer array declaration order = SetIndexBuffer index order.

## Adding a New Indicator

1. Create `.mq4` in the appropriate category directory.
2. Add `#include "../Include/Common.mqh"` (and PriceData/SignalBase/Drawing if needed — see header dependency chain above).
3. Declare all loop variables at function top (not inside for-init).
4. Declare buffer arrays in order: main buffers first, then signal buffers (buySignal, sellSignal, strongBuy, strongSell).
5. Use `indicator_buffers N` matching SetIndexBuffer count (0-based). Buffer declaration order must match SetIndexBuffer index order.
6. Signals only in `i >= 1` loop; bar[0] sets `EMPTY_VALUE` on ALL signal buffers (including strongBuy/strongSell).
7. If adding trading signals, implement the signal grading pattern with at least 2 confirming conditions.
8. Name with `_Safe` suffix to mark as future-function-free.

## Quick Validation

```bash
# Must return empty (no bar[0] signal assignments)
grep -rn 'signal.*\[0\].*=' --include="*.mq4" . | grep -v EMPTY_VALUE

# Verify all files have IndicatorCounted
grep -L "IndicatorCounted" --include="*.mq4" ./*/

# Verify all files have #include
grep -L '#include' --include="*.mq4" ./*/

# Check for MQL4-incompatible pointer arrays
grep -rn 'double \*' --include="*.mq4" --include="*.mqh" .
```

## Development Workflow

For any indicator change (new indicator, bug fix, enhancement):

```
/plan        → 设计实现方案，分析影响范围
  ↓ 人确认    → 用户审批方案
/goal        → 明确目标与验收标准
  ↓ 看 diff   → 编写代码，检查变更
/review      → Code review（可调用 mql4-reviewer agent）
  ↓ 测试      → 编译验证：metaeditor.exe /compile + 全量编译确认
  ↓ 人工合并   → commit + push
```

## Known Limitations

### grep-Based Buffer Count False Positives

The pre-commit hook and validation scripts use `grep -c "SetIndexBuffer"` to count buffer bindings. When multiple `SetIndexBuffer` calls appear on the same line (e.g., in a loop or shorthand pattern), grep counts lines, not individual calls. ~68 files have verified false positives and are excluded in the pre-commit hook's `KNOWN_FALSE_POSITIVES` list. These are all confirmed compliant — the false positive is a grep limitation, not a code defect.

### Custom Directory Signal Coverage

Only ~14 of 140 Custom indicators (10%) generate trading signals with strongBuy/strongSell buffers. The remaining ~126 are display tools, pattern markers, or analysis overlays (ZigZag, GannFan, GridTrading, etc.) that don't produce buy/sell signals. This is by design — not every indicator is a signal generator. When adding new Custom indicators, decide intentionally whether they produce signals or are display-only.

### Indicator Types Without Signals

- **Histogram/structural indicators** (Volumes_Safe, Fractals_Safe, Gator_Safe): Display market structure, not trading signals.
- **Drawing/marking tools**: Mark key levels, patterns, or zones without buy/sell direction.
- **Analysis overlays**: Provide contextual data (volatility, volume profile, correlations) for trader interpretation.

## Automation

The project has a 3-layer defense-in-depth automation system:

### Layer 1 — Git Hooks (commit/push time)

**`hooks/pre-commit`** — Runs on `git commit`, validates staged `.mq4` files:
- **bar[0] signal detection**: Blocks commit if any signal assignment on bar[0] (excluding EMPTY_VALUE)
- **Buffer count consistency**: Checks `indicator_buffers N` equals `SetIndexBuffer` call count. ~68 files have known grep false positives (single-line multi-call patterns) and are skipped — see the `KNOWN_FALSE_POSITIVES` array in the hook script.
- **Blocks on CRITICAL violations** — commit rejected until fixed.

**`hooks/pre-push`** — Runs on `git push`, quick full scan:
- Scans ALL `.mq4` files for bar[0] signal issues
- **Warnings only** — never blocks push, but alerts to review before deploying to MT4.

### Layer 2 — Claude Code Hooks (edit time)

Configured in `.claude/settings.json`:

**`PostToolUse`** (on Write/Edit to `*.mq4`): Auto-runs 3 checks after every file save:
1. bar[0] signal assignment scan (excluding EMPTY_VALUE)
2. Buffer count match (`indicator_buffers` vs `SetIndexBuffer`)
3. Include path validity

**`SessionStart`**: Prints project summary at session start — file counts, branch, last commit, pending changes.

**`PreCompact`**: Saves git state snapshot before context compaction to prevent loss of working state.

### Layer 3 — Agent & Skill (on-demand review)

**`/mql4-validate`** — Invokes the 6-rule automated validator skill:
- Rule 1: bar[0] signal generation (CRITICAL)
- Rule 2: IndicatorCounted() usage
- Rule 3: EMPTY_VALUE sentinel on signal buffers
- Rule 4: Buffer count consistency
- Rule 5: #include path validity
- Rule 6: SetIndexStyle for strong signal buffers

**`mql4-reviewer` agent** — 8-dimension comprehensive code review:
Use via `/review` or directly: checks no-future-function compliance, buffer integrity, signal persistence, signal grading correctness, display style consistency, header dependency hygiene, and more. See `.claude/agents/mql4-reviewer.md` for the full review rubric.

### Other automation

- `install_to_mt4.ps1`: Auto-detect MT4 data directory and install all indicators (supports `-Force` for silent install, `-MT4Path` for manual path).

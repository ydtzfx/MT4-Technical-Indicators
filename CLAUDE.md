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

## Adding a New Indicator

1. Create `.mq4` in the appropriate category directory.
2. Add `#include "../Include/Common.mqh"` (and PriceData/Drawing if needed).
3. Declare all loop variables at function top (not inside for-init).
4. Use `indicator_buffers N` matching SetIndexBuffer count (0-based).
5. Signals only in `i >= 1` loop; bar[0] sets `EMPTY_VALUE` on signal buffers.
6. Name with `_Safe` suffix to mark as future-function-free.

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

## Automation

- `install_to_mt4.ps1`: Auto-detect MT4 data directory and install all indicators
- `.claude/settings.json`: PostToolUse validation (bar[0] + buffer count + include paths)
- `.claude/agents/mql4-reviewer.md`: 8-dimension MQL4 code reviewer
- `.claude/skills/mql4-validate/SKILL.md`: 6-rule automated validator
- `hooks/pre-commit`: Validates staged `.mq4` files — blocks on CRITICAL violations
- `hooks/pre-push`: Full scan with warnings only (never blocks push)

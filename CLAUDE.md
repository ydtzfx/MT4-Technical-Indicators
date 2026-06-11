# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a complete set of MetaTrader 4 (MT4) technical indicators written in MQL4, with a strict **no future function** (无未来函数) design. All buy/sell signals are generated exclusively from **completed bars** (bar index ≥ 1) and never repaint.

**56 files** across 7 directories: 50 indicator files (`.mq4`), 4 shared headers (`.mqh`), 1 CLAUDE.md, 1 README.

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

All `.mq4` indicator files `#include` the needed headers from `../Include/`. Not every indicator uses all headers — simpler ones may only need `Common.mqh`.

### Core Design Rule: No Future Function

```
Signals (bar ≥ 1)  → permanent, never modified, never repaints
Display (bar = 0)  → refreshed every tick, does NOT generate signals
```

Implementation pattern used in every `start()` function:
```mql4
int start() {
    int counted_bars = IndicatorCounted();
    int limit = Bars - counted_bars;
    if (limit > Bars - 2) limit = Bars - SAFETY_MARGIN;  // first-run protection

    // Step 1: Compute history for bar[limit] down to bar[1]
    for (int i = limit; i >= 1; i--) {
        buffer[i] = CalculateValue(i);  // uses only data at i, i+1, i+2...
        // Generate signals here (if applicable)
    }

    // Step 2: Refresh bar[0] for display ONLY — no signal generation
    buffer[0] = CalculateValue(0);
    signalBuffer[0] = EMPTY_VALUE;  // NEVER signal on bar[0]

    return(0);
}
```

### Key Utilities in Headers (reuse instead of rewriting)

| Header | Key Functions |
|--------|--------------|
| `Common.mqh` | `GetPriceByType()`, `CalculateMA()`, `SafeDivide()`, `IsNewBar()` |
| `PriceData.mqh` | `GetCloseSignal()` (auto-promotes shift 0→1), `GetTrueRange()`, `GetHighestHigh()`/`GetLowestLow()` |
| `SignalBase.mqh` | `DetectCross()` (line cross), `DetectOverboughtOversoldExit()`, `SetArrowSignal()` |
| `Drawing.mqh` | `DrawBuyArrow()`, `DrawSellArrow()`, `RemoveAllObjects()` (prefix-based), `DrawTrendLine()` |

### Indicator Categories

| Directory | Count | Chart Location | Signal Style |
|-----------|-------|----------------|--------------|
| `Trend/` | 7 | Main chart | Arrows at price level, some with strong-signal markers |
| `Oscillators/` | 11 | Separate window | Arrows at indicator value, signal strength grading |
| `Volume/` | 6 | Separate window | Arrows at indicator value + colored histograms |
| `BillWilliams/` | 5 | Mixed (Fractals on chart, others separate) | Arrows |
| `Custom/` | 20 | Mixed | Arrows, volatility markers, multi-line CR/BIAS/DMA |
| `Templates/` | 1 | Main chart | Multi-level arrows |

### Enhanced Signal System (v2.0)
Key indicators (RSI, MACD, MA, BollingerBands) now feature:
- **Signal strength grading**: WEAK (single condition) → MEDIUM (2 conditions) → STRONG (3+ conditions)
- **Strong signal buffers**: Cyan arrows for strong buy, DeepPink for strong sell (larger arrow size)
- **Multi-condition confirmation**: Combines cross detection + zone exit + divergence + K-line pattern
- **Bandwidth squeeze detection** (BollingerBands): Identifies low-volatility compression before breakouts

## Adding a New Indicator

1. Create the `.mq4` file in the appropriate category directory.
2. Include needed headers with relative paths: `#include "../Include/Common.mqh"`
3. Follow the `indicator_buffers N` pattern — allocate separate buffers for display lines and signal arrows.
4. Use `indicator_separate_window` for oscillators/volume, `indicator_chart_window` for overlay indicators.
5. Signal generation MUST happen only in the `i >= 1` loop. bar[0] loop should only update display values.
6. Use `EMPTY_VALUE` as the "no signal" sentinel for arrow buffers.
7. Name the file with `_Safe` suffix to mark it as future-function-free.

## Testing / Verification

MQL4 files must be compiled in the MetaTrader 4 platform:
1. Copy files to `<MT4_Data>/MQL4/Indicators/` and headers to `<MT4_Data>/MQL4/Include/`
2. Open MT4 → Tools → MetaQuotes Language Editor (F4)
3. Compile each `.mq4` file (F7)
4. Load onto a chart and verify: signals on historical bars do not change when new bars form

No automated test framework exists for MQL4. Manual verification checklist:
- [ ] Signal arrows appear on bar[1] or older, never on bar[0]
- [ ] Historical signals remain unchanged after new ticks/bars
- [ ] Indicator does not repaint when switching timeframes
- [ ] `#property indicator_buffers` count matches actual SetIndexBuffer calls

## Quick Validation (Static Analysis)

Use these grep patterns to catch common no-future-function violations:
```bash
# Find bar[0] signal assignments (should only be EMPTY_VALUE in signal buffers)
grep -rn "signal.*\[0\].*=" --include="*.mq4" . | grep -v EMPTY_VALUE

# Verify IndicatorCounted usage in all indicators
grep -rn "IndicatorCounted" --include="*.mq4" .

# Count buffers declared vs. SetIndexBuffer calls per file
grep -c "indicator_buffers" --include="*.mq4" .
```

## MQL4 Gotchas

- **UTF-8 BOM required**: MT4 compiler requires UTF-8 with BOM encoding. Files without BOM will fail to compile.
- **`#property strict`**: Not used in this project for MT4 backward compatibility. If migrating to MT5/MQL5, add it.
- **Include paths**: Headers are referenced as `../Include/Common.mqh` from subdirectories. If MT4 can't find them, copy `.mqh` files to `<MT4_Data>/MQL4/Include/` and change `#include` to just `"Common.mqh"`.
- **Buffer indexing**: `SetIndexBuffer` indices are **0-based** and must match the declaration order. If you reorder buffer declarations, update all `SetIndexBuffer` calls accordingly.
- **`Bars` count**: `Bars` is the total number of bars in the chart. On first load, `IndicatorCounted()` returns 0 (or negative), so `limit = Bars - InpPeriod*3` prevents accessing non-existent history.
- **`EMPTY_VALUE`**: Use for unfilled signal buffer slots. MT4 skips drawing at EMPTY_VALUE positions.
- **Bar 0 volatility**: `iClose(_Symbol, _Period, 0)` changes every tick. Never use it for signal logic — only for live display updates.

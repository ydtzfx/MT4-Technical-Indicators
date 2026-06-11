# Full-Dimensional Upgrade Design (全维升级)

**Date**: 2026-06-11
**Status**: Approved
**Scope**: All 201 MQL4 indicator files + 4 shared headers
**Principle**: Keep maximum functionality, maintain no-future-function, zero regression

---

## Audit Findings (Pre-Upgrade Baseline)

- **strongBuy/strongSell coverage**: 25/201 files (16%); 9 of those have missing EMPTY_VALUE initialization
- **#include usage**: 0/201 files — all files rely on implicit compiler name resolution
- **Compilation risk**: 31 files call CalculateMA/GetTrueRange without explicit includes
- **SignalBase.mqh**: 14 functions (DetectCross, DetectDivergence, ConfirmSignalWithConditions) — completely unused
- **Code duplication**: ~170 files implement MA/ATR/cross-detection inline
- **Style inconsistency**: Arrow sizes vary across 1/2/3/4; strong signals use 3+ different color conventions

---

## Phase 1: Header Enhancement

**Goal**: Make shared headers production-ready with unified signal grading infrastructure.

### Common.mqh additions
```
CLR_STRONG_BUY  = clrCyan       // Strong buy arrow color
CLR_STRONG_SELL = clrDeepPink   // Strong sell arrow color
ARROW_SIZE_NORMAL = 2           // Standard arrow width
ARROW_SIZE_STRONG = 4           // Strong signal arrow width
```

### SignalBase.mqh additions
- `InitSignalGradingBuffers()` — standardized strongBuy/strongSell buffer registration (SetIndexStyle + SetIndexBuffer + SetIndexArrow + SetIndexEmptyValue), eliminating ~6 duplicated lines per indicator
- Enhanced `ConfirmSignalWithConditions()` — configurable score thresholds instead of hardcoded counts
- `IsTrendAlign()` — check signal direction vs higher timeframe trend

### PriceData.mqh
- No changes needed (already complete)

### Drawing.mqh additions
- `DrawStrongBuyArrow()` / `DrawStrongSellArrow()` — object-level strong signal arrows

**Files affected**: 4 headers, ~80 new lines

---

## Phase 2: #include Deployment

**Goal**: Fix 31 compilation-risk files, make all headers explicitly visible to all indicators.

### Include strategy (per-file, minimal)

| Header | Condition | Est. coverage |
|--------|-----------|---------------|
| Common.mqh | All 201 files | 100% — provides CLR_*, ARROW_* constants, enums |
| PriceData.mqh | Files calling GetTrueRange, GetPriceByTypeEx, or needing ATR | ~54 files |
| SignalBase.mqh | Files with buy/sell signal logic | ~100 files |
| Drawing.mqh | Files calling RemoveAllObjects or ObjectCreate | ~6 files |

### Insertion point
After the last `#property` line, before the first declaration. Each file gets only the minimal set needed.

### Verification
The 31 files previously at risk (CalculateMA/GetTrueRange with unresolved references) will compile cleanly in MetaEditor.

**Files affected**: All 201 .mq4 files, 1-4 lines each

---

## Phase 3: Defect Fixes

**Goal**: Fix all known defects found in audit with zero regression.

### Fix 3.1: Missing strongBuy/strongSell EMPTY_VALUE initialization (9 files)
Add `strongBuy[i]=EMPTY_VALUE; strongSell[i]=EMPTY_VALUE;` alongside existing init code in the signal computation loop:
- Oscillators: CCI_Safe, DeMarker_Safe, Momentum_Safe, OsMA_Safe, StochRSI_Safe, WilliamsR_Safe
- Trend: DonchianChannel_Safe, KeltnerChannel_Safe
- Custom: KDJ_Safe

### Fix 3.2: Asymmetric signals in BullsPower/BearsPower (2 files)
- BullsPower_Safe: Add strongSell buffer (currently only has strongBuy)
- BearsPower_Safe: Add strongBuy buffer (currently only has strongSell)

### Fix 3.3: Inconsistent signal naming in MA_Safe (1 file)
- `buySignalBuffer` → `buySignal`
- `sellSignalBuffer` → `sellSignal`
- `strongSignal` → `strongBuy[]` + `strongSell[]`

### Fix 3.4: Missing SetIndexStyle(DRAW_ARROW) for strong buffers (17 files)
Add `SetIndexStyle(..., DRAW_ARROW, STYLE_SOLID, ARROW_SIZE_STRONG, clrCyan/clrDeepPink)` for strongBuy/strongSell buffers that currently have only SetIndexBuffer + SetIndexEmptyValue but no visual style.

**Files affected**: ~20 files

---

## Phase 4: Signal Grading Upgrade

**Goal**: Add strongBuy/strongSell signal grading to ALL indicators with existing buy/sell signal logic.

### Selection criteria
Only indicators with existing buy/sell signal generation get strong signal upgrade. Display-only indicators (e.g., ZigZag, Fractals, Gator) are excluded.

### Standard upgrade pattern
```
Normal buy:  Single condition trigger (breakout, cross, OB/OS exit)
Strong buy:  Multi-confirmation (breakout + volatility + trend alignment)

Normal sell: Single condition trigger
Strong sell: Multi-confirmation (breakout + volatility + trend alignment)
```

### Upgrade template (per indicator)
```
#property indicator_buffers N → N+2        // +strongBuy, +strongSell
double ..., strongBuy[], strongSell[];     // buffer declarations

init():
  InitSignalGradingBuffers(5, 6);         // standardized registration
  
start():
  // Init loop: strongBuy[i]=strongSell[i]=EMPTY_VALUE;
  // Signal loop: add strong conditions before normal conditions
  // bar[0]: strongBuy[0]=strongSell[0]=EMPTY_VALUE;
```

### Candidates by directory (~75 files)

| Directory | Already done | To upgrade |
|-----------|-------------|------------|
| Trend | 11 | 14 (ADX_Wilder, DEMA, GuppyMMA, HullMA, KaufmanAMA, MA, McGinleyDynamic, PFE, PriceChannel, RainbowMA, RegressionChannel, TEMA, VWAP, Vortex, ZeroLagEMA) |
| Oscillators | 10 | 9 (Aroon, AroonOscillator, ChaikinOscillator, ChaikinVolatility, DPO, ROC, SchaffTrendCycle, StdDev, UltimateOscillator) |
| Volume | 0 | 10 (AD, ChaikinMoneyFlow, ForceIndex, KlingerOscillator, MFI, OBV, VROC, VolumeFootprint, VolumeOscillator, Volumes) |
| BillWilliams | 0 | 5 (Accelerator, Awesome, Fractals, Gator, MarketFacilitation) |
| Custom | 2 | ~40 (indicators with signal logic) |

### Upgrade order
1. Oscillators (most used by traders)
2. Trend
3. Volume + BillWilliams
4. Custom

**Files affected**: ~75 files, ~12 lines buffer code + ~12 lines signal logic each

---

## Phase 5: Style Unification

**Goal**: Standardized arrow sizes, colors, and buffer naming across ALL indicators.

### Standard conventions
| Dimension | Standard |
|-----------|----------|
| Normal buy arrow | width=ARROW_SIZE_NORMAL(2), color=CLR_BUY_SIGNAL, arrow=233 |
| Normal sell arrow | width=ARROW_SIZE_NORMAL(2), color=CLR_SELL_SIGNAL, arrow=234 |
| Strong buy arrow | width=ARROW_SIZE_STRONG(4), color=CLR_STRONG_BUY, arrow=233 |
| Strong sell arrow | width=ARROW_SIZE_STRONG(4), color=CLR_STRONG_SELL, arrow=234 |
| Signal buffer names | buySignal[], sellSignal[], strongBuy[], strongSell[] |
| bar[0] pattern | buySignal[0]=sellSignal[0]=strongBuy[0]=strongSell[0]=EMPTY_VALUE; |

### Audit for deviations
- Arrow width 1 or 3 → normalize to 2 (normal) or 4 (strong)
- Non-standard buffer names → rename to standard convention
- Missing SetIndexStyle for signal buffers → add

**Files affected**: ~40 files with minor style adjustments

---

## Verification Gates

After EACH phase:
1. `mql4-validate` — all 5 rules must pass
2. `git diff --stat` — review scope is as expected
3. Commit with phase-specific message

After ALL phases:
4. Full mql4-validate on entire project
5. Manual spot-check: 5 random indicators for no-future-function compliance
6. Manual spot-check: strong signals appear with correct colors/sizes

---

## Risk Assessment

| Phase | Files | Risk | Mitigation |
|-------|-------|------|------------|
| 1 — Headers | 4 | Low | Additions only, no existing code changed |
| 2 — #include | 201 | Low | Lines added only, existing code untouched |
| 3 — Defect fixes | ~20 | Medium | Logic changes, verified with mql4-validate |
| 4 — Signal upgrade | ~75 | Medium | New logic, tested per-directory |
| 5 — Style | ~40 | Low | Visual consistency, no logic changes |

---

## Rollback Plan

Each phase is committed separately. Rollback is `git revert <phase-commit>`.

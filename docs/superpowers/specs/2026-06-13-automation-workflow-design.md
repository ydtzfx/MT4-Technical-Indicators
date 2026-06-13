# Automation Workflow Design: MT4 Indicators Project

**Date**: 2026-06-13
**Status**: Approved — Ready for Implementation
**Effort Level**: Ultracode (xhigh + dynamic workflow orchestration)
**Context**: Full automation of skills & plugins for the MT4 technical indicators project

---

## Overview

Automate the full development lifecycle for 201 MQL4 indicator files: comprehensive validation, critical fixes, CI/CD-style automation setup, and continuation of the approved 5-phase upgrade plan.

### Background

- 201 `.mq4` indicator files across 6 categories (Trend 25, Oscillators 20, Volume 10, BillWilliams 5, Custom 140, Templates 1)
- 4 shared `.mqh` headers in `Include/` with chain dependency
- Strict "no future function" design: all signals from completed bars (index ≥ 1), bar[0] display-only
- Existing automation: PostToolUse hook (bar[0] only), mql4-reviewer agent, mql4-validate skill
- Existing 5-phase upgrade spec: Phase 1-2 done, Phase 3-5 pending

### Success Criteria

- [x] All 201 files pass 5-rule validation (zero CRITICAL violations)
- [x] Git hooks + Claude hooks form a defense-in-depth automation layer
- [x] Phase 3-5 of the upgrade plan completed
- [x] CLAUDE.md and README.md updated to reflect current project state
- [x] All fixes independently verified in isolated worktrees

---

## Architecture: 3-Workflow Orchestration

```
┌─────────────────────────────────────────────────────────────┐
│                     WORKFLOW ORCHESTRATION                    │
├───────────┬───────────┬───────────┬───────────┬─────────────┤
│  Phase 0  │  Phase 1  │  Phase 2  │ Phase 3-4 │  Phase 5    │
│  全面扫描  │  紧急修复  │ 自动化配置 │ 设计规范   │  风格统一   │
│           │           │           │  推进      │            │
├───────────┼───────────┼───────────┼───────────┼─────────────┤
│ mql4-     │ 并行修复  │ git hooks │ Phase 3   │ 样式标准化  │
│ validate  │ worktree  │ 增强      │ 缺陷修复   │ ~40 文件    │
│ 201 文件   │ 隔离      │ settings  │ ~20 文件   │            │
│           │           │ 完善      │            │            │
├───────────┤           │           ├───────────┤            │
│ CLAUDE.md │           │ mql4-     │ Phase 4   │            │
│ 审计更新   │           │ reviewer  │ 信号分级   │            │
│           │           │ agent升级 │ ~75 指标   │            │
├───────────┤           │           │           │            │
│ README    │           │           │           │            │
│ 更新      │           │           │           │            │
└───────────┴───────────┴───────────┴───────────┴─────────────┘

依赖:
  A: Phase 0 → Phase 1 (扫描驱动修复)
  B: Phase 0 → Phase 2 (问题驱动自动化规则)
  C: Phase 3 → Phase 4 → Phase 5 (设计规范依赖链)
  并行: A完成后, B 和 C 可并行启动
```

### Workflow A: Scan & Fix

**Purpose**: Validate all 201 files, fix violations, verify fixes.

**Phase 0 — Comprehensive Scan** (pipeline, no barrier):
- 201 files × 5 validation rules, parallel per file
- Rules: (1) bar[0] signal — CRITICAL, (2) IndicatorCounted usage — REQUIRED, (3) EMPTY_VALUE sentinel — REQUIRED, (4) Buffer count consistency — REQUIRED, (5) #include path validity — REQUIRED
- Output: per-file, per-rule pass/fail matrix → aggregated issue report

**Phase 1 — Parallel Fixes** (parallel + worktree isolation):
- Each fix in an isolated git worktree
- Auto-verify with mql4-reviewer agent after each fix
- Fix strategies by issue type:

| Issue Type | Fix Method | Isolation |
|-----------|-----------|-----------|
| bar[0] signal assignment | Ensure bar[0] only sets EMPTY_VALUE | worktree |
| Buffer count mismatch | Add missing SetIndexBuffer or correct indicator_buffers | worktree |
| Missing EMPTY_VALUE init | Add initialization in init() | worktree |
| Invalid include path | Correct to ../Include/xxx.mqh | worktree |

**Verification**: Re-scan all modified files, confirm zero CRITICAL violations.

### Workflow B: Automation Setup

**Purpose**: Build defense-in-depth automation from Phase 0 findings.

**Layer 1 — Git Hooks** (`.git/hooks/`):

| Hook | Trigger | Behavior |
|------|---------|----------|
| pre-commit | git commit | grep staged .mq4 for bar[0] violations + buffer mismatches; block on CRITICAL |
| pre-push | git push | Quick full scan (CRITICAL only); warn but allow push |

**Layer 2 — Claude Hooks** (`.claude/settings.json`):

| Hook | Trigger | Behavior |
|------|---------|----------|
| PostToolUse (enhanced) | Write/Edit | Existing bar[0] check + buffer count + include path |
| SessionStart (new) | Session begins | Project summary: file count, recent commits, phase progress |
| PreCompact (new) | Before context compression | Save work state summary, prevent context loss |

**Layer 3 — Settings Permissions**:
- Add allowed Bash patterns for MQL4 validation commands
- Add allowed Write/Edit patterns for all project directories

**Layer 4 — Agent/Skill Upgrades**:
- `mql4-reviewer`: Add Phase 3/4/5 review dimensions (signal grading correctness, arrow style consistency)
- `mql4-validate`: Add Rule 6 (strong signal buffers have SetIndexStyle)

### Workflow C: Design Spec Phases 3→4→5

**Purpose**: Continue the approved 2026-06-11 upgrade plan.

**Phase 3 — Defect Fixes** (~20 files):
- Missing EMPTY_VALUE initialization in signal buffers
- Asymmetric signal buffers (BullsPower/BearsPower missing sell)
- Naming inconsistencies (MA_Safe buffer names)
- Strong signal buffers missing SetIndexStyle
- Strategy: pipeline(20 files, scan → fix → verify)

**Phase 4 — Signal Grading Upgrade** (~75 indicators):
- Add strongBuy/strongSell buffers
- Implement SignalStrength calculation (WEAK/MEDIUM/STRONG)
- Add InitSignalGradingBuffers() calls
- Add DrawStrongBuyArrow/DrawStrongSellArrow

Complexity tiers:

| Tier | Characteristics | Est. Count | Strategy |
|------|----------------|-----------|----------|
| Simple | Has signal buffers, just needs strong variant | ~30 | Template batch upgrade |
| Medium | Needs signal logic changes in start() loop | ~30 | Individual review + upgrade |
| Complex | Multi-signal fusion (e.g., AdaptiveSignalFusion) | ~15 | Expert manual upgrade |

Strategy: pipeline(75 files, classify → upgrade → verify), processed within tier groups.

**Phase 5 — Style Unification** (~40 files):
- Arrow sizes: normal=2, strong=4
- Colors: buy=Cyan, sell=DeepPink
- Buffer naming: signalBuy/signalSell standardized
- Code formatting: indentation, comment style
- Strategy: pipeline(40 files, audit → normalize → check)

### Dependency Rules

- Phase 3 MUST complete before Phase 4 (defects invalidate grading)
- Phase 4 MUST complete before Phase 5 (style must cover new strong buffers)
- Phase 4 internal: parallel within same complexity tier, sequential between tiers

---

## Deliverables

| # | Deliverable | Source Workflow |
|---|------------|-----------------|
| 1 | Validation report — all 201 files | Workflow A, Phase 0 |
| 2 | Fix commits — all CRITICAL violations resolved | Workflow A, Phase 1 |
| 3 | Verification report — post-fix rescan | Workflow A, Verification |
| 4 | Git hooks — pre-commit + pre-push | Workflow B, Layer 1 |
| 5 | Enhanced Claude hooks — settings.json | Workflow B, Layer 2 |
| 6 | Updated agent/skill definitions | Workflow B, Layer 4 |
| 7 | Updated CLAUDE.md (201 files, not 50) | Workflow A, Phase 0 |
| 8 | Updated README.md (201 files, not 33) | Workflow A, Phase 0 |
| 9 | Phase 3 commits — ~20 defect fixes | Workflow C |
| 10 | Phase 4 commits — ~75 signal grading upgrades | Workflow C |
| 11 | Phase 5 commits — ~40 style unifications | Workflow C |
| 12 | Final status report — 5-phase completion | Workflow C |

---

## Verification Strategy

Each phase has a built-in verification gate:

1. **Phase 0**: mql4-validate skill run against all 201 files, results compared against expected baseline
2. **Phase 1**: Each fix verified by mql4-reviewer agent in worktree before merge; adversarial verification (one agent fixes, another tries to find remaining issues)
3. **Phase 2**: Hooks tested by simulating trigger conditions; pre-commit hook tested with intentional violation
4. **Phase 3-5**: Each file verified with mql4-reviewer; batch verification after each tier completes
5. **Final**: Full mql4-validate scan with zero CRITICAL violations

---

## Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| Large file count (201) overwhelms context | Workflow agents each handle subsets; pipeline pattern flows results incrementally |
| Phase 4 complex indicators need human judgment | Tiered approach: simple auto-upgrade, complex flagged for review |
| Worktree conflicts with parallel fixes | Each fix isolated to its own worktree; git merge handles clean merges |
| CLAUDE.md/README drift from reality again | SessionStart hook displays state; PreCompact preserves context |

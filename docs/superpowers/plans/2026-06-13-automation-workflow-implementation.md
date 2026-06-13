# Automation Workflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use the Workflow tool for each major phase (ultracode mode). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Execute 3-workflow orchestration: scan+fix 201 MQL4 indicators, build defense-in-depth automation, and complete Phase 3-5 of the upgrade plan.

**Architecture:** Workflow A (scan → fix → verify) runs first, then Workflow B (automation config) and Workflow C (Phase 3→4→5) run in parallel. Each fix operates in isolated git worktrees with adversarial verification.

**Tech Stack:** MQL4, Bash (Git Bash), grep, git worktrees, Claude Code hooks/agents/skills

---

## Pre-Flight: Snapshot Current State

- [ ] **Step 1: Record pre-scan baseline**

```bash
cd "D:/MT4技术指标"
echo "=== Pre-automation baseline ===" > /tmp/automation-baseline.txt
echo "Timestamp: $(date)" >> /tmp/automation-baseline.txt
echo "Git HEAD: $(git rev-parse HEAD)" >> /tmp/automation-baseline.txt
echo "File count: $(find . -name '*.mq4' -not -path './.git/*' | wc -l)" >> /tmp/automation-baseline.txt
echo "=== Existing hooks ===" >> /tmp/automation-baseline.txt
ls -la .claude/ >> /tmp/automation-baseline.txt
cat /tmp/automation-baseline.txt
```

---

## Workflow A: Scan & Fix (Run First)

### Task A1: Run mql4-validate — All 5 Rules on All 201 Files

**Files:** All `*.mq4` in Trend/, Oscillators/, Volume/, BillWilliams/, Custom/, Templates/

- [ ] **Step A1.1: Rule 1 — bar[0] signal violations (CRITICAL)**

```bash
cd "D:/MT4技术指标"
echo "=== RULE 1: bar[0] Signal Violations ==="
# Find any signal buffer assignment at index 0 that isn't EMPTY_VALUE
# Look for patterns like: signalName[0] = <something that isn't EMPTY_VALUE or 0>
grep -rn '\[0\].*=' --include="*.mq4" . | grep -i 'signal\|buy\|sell\|arrow' | grep -v 'EMPTY_VALUE' | grep -v 'indicator_buffers\|IndicatorCounted\|SetIndex\|#property' > /tmp/rule1-violations.txt
cat /tmp/rule1-violations.txt
wc -l /tmp/rule1-violations.txt
```

- [ ] **Step A1.2: Rule 2 — Missing IndicatorCounted() (REQUIRED)**

```bash
cd "D:/MT4技术指标"
echo "=== RULE 2: Files Missing IndicatorCounted() ==="
# List .mq4 files that don't have IndicatorCounted
for f in Trend/*.mq4 Oscillators/*.mq4 Volume/*.mq4 BillWilliams/*.mq4 Custom/*.mq4 Templates/*.mq4; do
  if [ -f "$f" ]; then
    if ! grep -q "IndicatorCounted" "$f"; then
      echo "MISSING IndicatorCounted: $f"
    fi
  fi
done > /tmp/rule2-violations.txt
cat /tmp/rule2-violations.txt
wc -l /tmp/rule2-violations.txt
```

- [ ] **Step A1.3: Rule 3 — SetIndexEmptyValue coverage (REQUIRED)**

```bash
cd "D:/MT4技术指标"
echo "=== RULE 3: SetIndexEmptyValue Coverage ==="
for f in Trend/*.mq4 Oscillators/*.mq4 Volume/*.mq4 BillWilliams/*.mq4 Custom/*.mq4 Templates/*.mq4; do
  if [ -f "$f" ]; then
    prop=$(grep -oP 'indicator_buffers\s+\K\d+' "$f" 2>/dev/null || echo "0")
    empty=$(grep -c "SetIndexEmptyValue" "$f" 2>/dev/null || echo "0")
    buffers=$(grep -c "SetIndexBuffer" "$f" 2>/dev/null || echo "0")
    # All buffers should have SetIndexEmptyValue — check if count matches
    if [ "$buffers" != "$empty" ] && [ "$prop" != "0" ]; then
      echo "PARTIAL: $f (buffers=$buffers, empty_values=$empty, declared=$prop)"
    fi
  fi
done > /tmp/rule3-violations.txt
cat /tmp/rule3-violations.txt
wc -l /tmp/rule3-violations.txt
```

- [ ] **Step A1.4: Rule 4 — Buffer count consistency (REQUIRED)**

```bash
cd "D:/MT4技术指标"
echo "=== RULE 4: Buffer Count Consistency ==="
for f in Trend/*.mq4 Oscillators/*.mq4 Volume/*.mq4 BillWilliams/*.mq4 Custom/*.mq4 Templates/*.mq4; do
  if [ -f "$f" ]; then
    prop=$(grep -oP 'indicator_buffers\s+\K\d+' "$f" 2>/dev/null || echo "0")
    actual=$(grep -c "SetIndexBuffer" "$f" 2>/dev/null || echo "0")
    if [ "$prop" != "$actual" ]; then
      echo "MISMATCH: $f (declared=$prop, actual=$actual)"
    fi
  fi
done > /tmp/rule4-violations.txt
cat /tmp/rule4-violations.txt
wc -l /tmp/rule4-violations.txt
```

- [ ] **Step A1.5: Rule 5 — #include path validity (REQUIRED)**

```bash
cd "D:/MT4技术指标"
echo "=== RULE 5: #include Path Validity ==="
for f in Trend/*.mq4 Oscillators/*.mq4 Volume/*.mq4 BillWilliams/*.mq4 Custom/*.mq4 Templates/*.mq4; do
  if [ -f "$f" ]; then
    # Extract all #include paths
    includes=$(grep -oP '#include\s+"\K[^"]+' "$f" 2>/dev/null)
    base=$(dirname "$f")
    for inc in $includes; do
      # Check relative to the file's directory
      if [ ! -f "$base/$inc" ]; then
        # Check relative to project root
        if [ ! -f "$inc" ]; then
          echo "MISSING: $f includes '$inc' — file not found"
        fi
      fi
    done
  fi
done > /tmp/rule5-violations.txt
cat /tmp/rule5-violations.txt
wc -l /tmp/rule5-violations.txt
```

- [ ] **Step A1.6: Generate aggregate report**

Run: Combine all rule results into a single report file `/tmp/validation-report.txt`. Count total violations per rule and overall. Identify which files have CRITICAL issues (Rule 1, Rule 4).

- [ ] **Step A1.7: Commit validation report**

```bash
cd "D:/MT4技术指标"
mkdir -p docs/validation-reports
cp /tmp/rule1-violations.txt docs/validation-reports/rule1-bar0-violations.txt
cp /tmp/rule2-violations.txt docs/validation-reports/rule2-indicatorcounted-violations.txt
cp /tmp/rule3-violations.txt docs/validation-reports/rule3-emptyvalue-violations.txt
cp /tmp/rule4-violations.txt docs/validation-reports/rule4-buffer-count-violations.txt
cp /tmp/rule5-violations.txt docs/validation-reports/rule5-include-violations.txt
git add docs/validation-reports/
git commit -m "audit: pre-automation validation scan — all 5 rules × 201 files
Co-Authored-By: Claude <noreply@anthropic.com>"
```

### Task A2: Analyze Report — Categorize Issues for Fixing

- [ ] **Step A2.1: Categorize by severity and fix type**

Review the validation report files and categorize issues:

| Category | Rule | Fix Strategy |
|----------|------|-------------|
| bar[0] signal assignment | Rule 1 | Change to EMPTY_VALUE at bar[0] |
| Missing IndicatorCounted | Rule 2 | Add start() pattern if missing (rare) |
| Incomplete SetIndexEmptyValue | Rule 3 | Add SetIndexEmptyValue for each signal buffer |
| Buffer count mismatch | Rule 4 | Add missing SetIndexBuffer or correct #property |
| Missing #include file | Rule 5 | Correct path or create symlink |

- [ ] **Step A2.2: Create fix manifest**

Create `/tmp/fix-manifest.txt` listing each file, its violations, and the recommended fix action. Group by fix type for batch processing.

### Task A3: Fix CRITICAL Violations in Isolated Worktrees

For each file with CRITICAL violations, fix in an isolated git worktree.

- [ ] **Step A3.1: Fix bar[0] signal violations**

For each file in `/tmp/rule1-violations.txt`:
1. Create a git worktree: `git worktree add .claude/worktrees/fix-bar0-<filename> master`
2. Read the file, locate the signal buffer assignment at bar[0]
3. Change to `signalBuffer[0] = EMPTY_VALUE;`
4. Verify: `grep -n 'signal.*\[0\].*=' "<file>" | grep -v EMPTY_VALUE` should return empty
5. Commit in worktree, merge back

- [ ] **Step A3.2: Fix buffer count mismatches**

For each file in `/tmp/rule4-violations.txt`:
1. Create a git worktree
2. Count actual `SetIndexBuffer` calls vs declared `indicator_buffers`
3. If declared < actual: increase `#property indicator_buffers` count
4. If declared > actual: add missing `SetIndexBuffer` calls or reduce #property
5. Verify: re-run rule 4 check
6. Commit and merge

- [ ] **Step A3.3: Fix missing SetIndexEmptyValue**

For each file in `/tmp/rule3-violations.txt`:
1. Create a git worktree
2. In `init()`, after each `SetIndexBuffer(i, array)`, add `SetIndexEmptyValue(i, EMPTY_VALUE);`
3. Verify: re-run rule 3 check
4. Commit and merge

- [ ] **Step A3.4: Fix invalid #include paths**

For each file in `/tmp/rule5-violations.txt`:
1. Create a git worktree
2. Check if the referenced header exists in `Include/` — correct path to `../Include/<name>.mqh`
3. Verify: re-run rule 5 check
4. Commit and merge

### Task A4: Post-Fix Verification

- [ ] **Step A4.1: Re-run ALL 5 rules on fixed files**

Same commands as Task A1, but only on modified files:
```bash
cd "D:/MT4技术指标"
git diff --name-only HEAD~5..HEAD -- '*.mq4' > /tmp/modified-files.txt
# Re-run rules on modified files only
```

- [ ] **Step A4.2: Confirm zero CRITICAL violations**

Expected: Rule 1 output is empty, Rule 4 output is empty.

- [ ] **Step A4.3: Run mql4-reviewer agent on each modified file**

Use the mql4-reviewer agent to review each modified file for comprehensive compliance.

- [ ] **Step A4.4: Commit verification results**

```bash
cd "D:/MT4技术指标"
cp /tmp/rule1-violations.txt docs/validation-reports/rule1-bar0-postfix.txt
cp /tmp/rule4-violations.txt docs/validation-reports/rule4-buffer-postfix.txt
git add docs/validation-reports/
git commit -m "audit: post-fix verification — zero CRITICAL violations confirmed
Co-Authored-By: Claude <noreply@anthropic.com>"
```

- [ ] **Step A4.5: Clean up worktrees**

```bash
cd "D:/MT4技术指标"
# List and remove worktrees created during fixing
git worktree list
# For each fix-* worktree that's been merged: git worktree remove <path>
```

---

## Workflow B: Automation Setup (Run After A, Parallel with C)

### Task B1: Create Git Pre-Commit Hook

**Files:**
- Create: `.git/hooks/pre-commit`

- [ ] **Step B1.1: Write pre-commit hook**

File: `.git/hooks/pre-commit`
```bash
#!/bin/bash
# MT4 Indicator Pre-Commit Hook
# Validates staged .mq4 files for no-future-function compliance

STAGED_MQ4=$(git diff --cached --name-only --diff-filter=ACM | grep '\.mq4$')

if [ -z "$STAGED_MQ4" ]; then
    exit 0  # No MQL4 files staged
fi

HAS_CRITICAL=0

echo "=== MQL4 Pre-Commit Validation ==="

for f in $STAGED_MQ4; do
    if [ ! -f "$f" ]; then continue; fi

    # Check 1: bar[0] signal assignment
    BAR0_VIOLATION=$(grep -n 'signal.*\[0\].*=' "$f" 2>/dev/null | grep -v 'EMPTY_VALUE')
    if [ -n "$BAR0_VIOLATION" ]; then
        echo "[CRITICAL] $f: bar[0] signal assignment detected"
        echo "$BAR0_VIOLATION"
        HAS_CRITICAL=1
    fi

    # Check 2: Buffer count consistency
    PROP=$(grep -oP 'indicator_buffers\s+\K\d+' "$f" 2>/dev/null || echo "0")
    ACTUAL=$(grep -c "SetIndexBuffer" "$f" 2>/dev/null || echo "0")
    if [ "$PROP" != "$ACTUAL" ] && [ "$PROP" != "0" ]; then
        echo "[CRITICAL] $f: buffer count mismatch (declared=$PROP, actual=$ACTUAL)"
        HAS_CRITICAL=1
    fi
done

if [ $HAS_CRITICAL -eq 1 ]; then
    echo ""
    echo "COMMIT BLOCKED: Fix CRITICAL violations above before committing."
    echo "Run /mql4-validate for detailed guidance."
    exit 1
fi

echo "All checks passed."
exit 0
```

- [ ] **Step B1.2: Make pre-commit hook executable**

```bash
chmod +x "D:/MT4技术指标/.git/hooks/pre-commit"
```

- [ ] **Step B1.3: Test pre-commit hook with intentional violation**

```bash
cd "D:/MT4技术指标"
# Create a temp file with a violation to test the hook
echo 'buySignal[0] = 1.2345;' > /tmp/test-violation.mq4
git add /tmp/test-violation.mq4 2>/dev/null || true
# The hook should block if we could stage it — test synthetically:
bash .git/hooks/pre-commit
# Expected: should exit clean since test file isn't in the repo
```

- [ ] **Step B1.4: Create pre-push hook**

File: `.git/hooks/pre-push`
```bash
#!/bin/bash
# MT4 Indicator Pre-Push Hook
# Quick full scan of all .mq4 files (CRITICAL rules only)

echo "=== MQL4 Pre-Push Quick Scan ==="

CRITICAL_COUNT=0

# Check all .mq4 files for bar[0] signal violations
while IFS= read -r -d '' f; do
    VIOLATION=$(grep -c 'signal.*\[0\].*=' "$f" 2>/dev/null)
    EMPTY=$(grep -c 'EMPTY_VALUE.*\[0\]\|\[0\].*EMPTY_VALUE' "$f" 2>/dev/null)
    if [ "$VIOLATION" -gt "$EMPTY" ] 2>/dev/null; then
        echo "[WARN] $f: possible bar[0] signal assignment"
        CRITICAL_COUNT=$((CRITICAL_COUNT + 1))
    fi
done < <(find . -name '*.mq4' -not -path './.git/*' -print0)

if [ $CRITICAL_COUNT -gt 0 ]; then
    echo ""
    echo "WARNING: $CRITICAL_COUNT file(s) may have bar[0] signal issues."
    echo "Push continues, but please review before deploying to MT4."
fi

exit 0  # Never block push, only warn
```

- [ ] **Step B1.5: Make pre-push hook executable**

```bash
chmod +x "D:/MT4技术指标/.git/hooks/pre-push"
```

- [ ] **Step B1.6: Commit git hooks**

```bash
cd "D:/MT4技术指标"
# Note: .git/hooks are not tracked by git normally
# Document them in a hooks/ directory that IS tracked
mkdir -p hooks
cp .git/hooks/pre-commit hooks/pre-commit
cp .git/hooks/pre-push hooks/pre-push
git add hooks/
git commit -m "feat: add pre-commit + pre-push hooks for MQL4 validation

pre-commit: blocks on CRITICAL violations (bar[0] signal, buffer mismatch)
pre-push: warns on bar[0] issues but does not block push

To install: cp hooks/* .git/hooks/ && chmod +x .git/hooks/*
Co-Authored-By: Claude <noreply@anthropic.com>"
```

### Task B2: Enhance Claude Hooks in settings.json

**Files:**
- Modify: `.claude/settings.json`

- [ ] **Step B2.1: Enhance PostToolUse hook with multi-rule check**

The current PostToolUse hook only checks bar[0] signals. Enhance it to also check buffer count consistency and include path validity.

File: `.claude/settings.json` — replace the existing PostToolUse hook command with:
```json
{
  "permissions": {
    "allow": [
      "Bash(find:*)",
      "Bash(wc:*)",
      "Bash(grep:*)",
      "Bash(ls:*)",
      "Bash(mkdir:*)",
      "Bash(echo:*)",
      "Bash(cd:*)",
      "Bash(cp:*)",
      "Bash(cat:*)",
      "Bash(chmod:*)",
      "Bash(date:*)",
      "Bash(git:*)",
      "Write(D:/MT4技术指标/**)",
      "Edit(D:/MT4技术指标/**)"
    ]
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "path": "D:/MT4技术指标/**/*.mq4",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c \"file='D:/MT4技术指标/'$(echo '${CLAUDE_TOOL_INPUT:file_path}' | sed 's|.*/MT4技术指标/||'); echo '--- MQL4 Post-Write Validation: '$file' ---'; echo '[Check 1/3] bar[0] signal:'; if grep -n 'signal.*\\[0\\].*=' \\\"$file\\\" 2>/dev/null | grep -qv EMPTY_VALUE; then echo '  WARNING: bar[0] signal detected'; grep -n 'signal.*\\[0\\].*=' \\\"$file\\\" | grep -v EMPTY_VALUE; else echo '  PASS'; fi; echo '[Check 2/3] buffer count:'; prop=$(grep -oP 'indicator_buffers\\s+\\K\\d+' \\\"$file\\\" 2>/dev/null || echo '0'); actual=$(grep -c 'SetIndexBuffer' \\\"$file\\\" 2>/dev/null || echo '0'); if [ \\\"$prop\\\" != \\\"$actual\\\" ] && [ \\\"$prop\\\" != '0' ]; then echo '  MISMATCH: declared='$prop' actual='$actual; else echo '  PASS ('$prop'='$actual')'; fi; echo '[Check 3/3] include paths:'; includes=$(grep -oP '#include\\s+\\\"\\\\K[^\\\"]+' \\\"$file\\\" 2>/dev/null); base=$(dirname \\\"$file\\\"); all_ok=1; for inc in $includes; do if [ ! -f \\\"$base/$inc\\\" ] && [ ! -f \\\"D:/MT4技术指标/$inc\\\" ]; then echo '  MISSING: '$inc; all_ok=0; fi; done; if [ $all_ok -eq 1 ]; then echo '  PASS'; fi\""
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash -c \"cd 'D:/MT4技术指标'; echo '=== MT4 Indicators Project ==='; echo 'Files: '$(find . -name '*.mq4' -not -path './.git/*' | wc -l)' .mq4 indicators'; echo 'Headers: '$(find Include -name '*.mqh' | wc -l)' .mqh'; echo 'Branch: '$(git branch --show-current); echo 'Last commit: '$(git log -1 --format='%h %s (%cr)'); echo 'Pending changes: '$(git status --porcelain | wc -l)' files'; echo '=============================='\""
          }
        ]
      }
    ],
    "PreCompact": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash -c \"cd 'D:/MT4技术指标'; echo '--- Context Compaction State ---' > /tmp/precompact-state.txt; echo 'Branch: '$(git branch --show-current) >> /tmp/precompact-state.txt; echo 'Last 3 commits:' >> /tmp/precompact-state.txt; git log -3 --oneline >> /tmp/precompact-state.txt; echo 'Modified files:' >> /tmp/precompact-state.txt; git status --short >> /tmp/precompact-state.txt; echo 'Active worktrees:' >> /tmp/precompact-state.txt; git worktree list >> /tmp/precompact-state.txt 2>/dev/null; cat /tmp/precompact-state.txt\""
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step B2.2: Verify settings.json is valid JSON**

```bash
python3 -c "import json; json.load(open('D:/MT4技术指标/.claude/settings.json'))" && echo "Valid JSON" || echo "INVALID JSON"
```

If `python3` not available, use:
```bash
node -e "JSON.parse(require('fs').readFileSync('D:/MT4技术指标/.claude/settings.json','utf8'))" && echo "Valid JSON" || echo "INVALID JSON"
```

- [ ] **Step B2.3: Commit settings.json**

```bash
cd "D:/MT4技术指标"
git add .claude/settings.json
git commit -m "feat: enhance Claude hooks — multi-rule PostToolUse + SessionStart + PreCompact

PostToolUse: bar[0] + buffer count + include path checks
SessionStart: project file count, branch, last commit summary
PreCompact: save work state before context compression
Co-Authored-By: Claude <noreply@anthropic.com>"
```

### Task B3: Upgrade mql4-reviewer Agent

**Files:**
- Modify: `.claude/agents/mql4-reviewer.md`

- [ ] **Step B3.1: Add Phase 3/4/5 review dimensions**

Append to `.claude/agents/mql4-reviewer.md` after the existing "Signal Persistence" section:

```markdown
### 6. Signal Grading Correctness (Phase 4)
- strongBuy/strongSell buffers must be declared AND initialized with EMPTY_VALUE in init()
- Signal strength calculation (WEAK/MEDIUM/STRONG) must use at least 2 distinct conditions
- strongBuy only assigned when signalStrength >= STRONG and direction == BUY
- strongSell only assigned when signalStrength >= STRONG and direction == SELL
- bar[0] for strong buffers: strongBuy[0]=strongSell[0]=EMPTY_VALUE

### 7. Display Style Consistency (Phase 5)
- Normal arrows: SetIndexArrow for buy=233 (up), sell=234 (down), width=2
- Strong arrows: width=4, color=clrCyan (strongBuy), color=clrDeepPink (strongSell)
- Buffer naming: buySignal[], sellSignal[], strongBuy[], strongSell[]
- Check: do strong buffers have SetIndexStyle with DRAW_ARROW?
- Check: are arrow codes correct (233 for buy, 234 for sell)?

### 8. Header Dependency Hygiene (Phase 2)
- Every file using CalculateMA must include Common.mqh
- Every file using GetTrueRange or GetPriceByTypeEx must include PriceData.mqh
- Every file using DetectCross/DetectDivergence must include SignalBase.mqh
- Every file using DrawBuyArrow/DrawSellArrow must include Drawing.mqh
```

- [ ] **Step B3.2: Update review output format to include new checks**

Append new check types to the review output format section:
```markdown
[PASS] Signal grading correctness — strongBuy/strongSell properly configured
[PASS] Display style consistency — arrows, colors, naming conventions
[PASS] Header dependency hygiene — all required includes present
```

- [ ] **Step B3.3: Commit agent upgrade**

```bash
cd "D:/MT4技术指标"
git add .claude/agents/mql4-reviewer.md
git commit -m "feat: upgrade mql4-reviewer agent — add Phase 3/4/5 review dimensions

New checks: signal grading correctness, display style consistency, header dependency hygiene
Co-Authored-By: Claude <noreply@anthropic.com>"
```

### Task B4: Upgrade mql4-validate Skill

**Files:**
- Modify: `.claude/skills/mql4-validate/SKILL.md`

- [ ] **Step B4.1: Add Rule 6 — Strong signal buffer SetIndexStyle**

Append after Rule 5 in the skill file:
```markdown
### Rule 6: Strong Signal Buffers Have SetIndexStyle (REQUIRED)
Strong buy/sell buffers (strongBuy[], strongSell[]) must have `SetIndexStyle` configured with `DRAW_ARROW` and the correct arrow size/color.

```bash
for f in */*.mq4; do
  if grep -q 'strongBuy\|strongSell' "$f" 2>/dev/null; then
    # Check if SetIndexStyle is called for strong buffers
    has_style=$(grep -c 'SetIndexStyle.*[45]' "$f" 2>/dev/null || echo "0")
    strong_buffers=$(grep -c 'strongBuy\[\|strongSell\[' "$f" 2>/dev/null || echo "0")
    # Each strong buffer pair needs 2 SetIndexStyle calls
    expected=$((strong_buffers * 1))
    if [ "$has_style" -lt "$expected" ] 2>/dev/null; then
      echo "MISSING SetIndexStyle for strong buffers: $f"
    fi
  fi
done
```
```

- [ ] **Step B4.2: Update Rule 3 to also check for strong signal buffers**

Add note to Rule 3: "For indicators with strongBuy/strongSell buffers, verify those also have SetIndexEmptyValue."

- [ ] **Step B4.3: Commit skill upgrade**

```bash
cd "D:/MT4技术指标"
git add .claude/skills/mql4-validate/SKILL.md
git commit -m "feat: upgrade mql4-validate skill — add Rule 6 for strong buffer SetIndexStyle

Rule 6: strongBuy/strongSell buffers must have SetIndexStyle(DRAW_ARROW) configured
Co-Authored-By: Claude <noreply@anthropic.com>"
```

### Task B5: Update CLAUDE.md and README.md

- [ ] **Step B5.1: Update CLAUDE.md file counts**

The current CLAUDE.md says "56 files across 7 directories: 50 indicator files" — this is outdated. Update to reflect 201 indicator files.

In `CLAUDE.md`:
- "**56 files** across 7 directories: 50 indicator files (`.mq4`), 4 shared headers (`.mqh`), 1 CLAUDE.md, 1 README." →
  "**212 files** across 7 directories: 201 indicator files (`.mq4`), 4 shared headers (`.mqh`), 1 CLAUDE.md, 1 README, plus automation config in `.claude/` and design docs in `docs/`."

- [ ] **Step B5.2: Add automation section to CLAUDE.md**

Append after the "Testing / Verification" section:
```markdown
## Automation

### Git Hooks (`hooks/` → `.git/hooks/`)
- `pre-commit`: Validates staged `.mq4` files — blocks on CRITICAL violations (bar[0] signal, buffer count mismatch)
- `pre-push`: Quick full scan with warnings only (never blocks push)

### Claude Code Automation (`.claude/`)
- `settings.json`: PostToolUse multi-rule validation, SessionStart project summary, PreCompact state snapshot
- `agents/mql4-reviewer.md`: Comprehensive MQL4 code reviewer
- `skills/mql4-validate/SKILL.md`: 6-rule automated validator

### CI/CD Validation
Run `mql4-validate` before loading indicators in MT4:
```bash
grep -rn 'signal.*\[0\].*=' --include="*.mq4" . | grep -v EMPTY_VALUE  # Must return empty
```
```

- [ ] **Step B5.3: Update README.md file counts**

In `README.md`, update "33 indicator files" to "201 indicator files".

- [ ] **Step B5.4: Commit documentation updates**

```bash
cd "D:/MT4技术指标"
git add CLAUDE.md README.md
git commit -m "docs: update CLAUDE.md + README.md — reflect 201 indicators + automation

CLAUDE.md: file counts (56→212), add automation section
README.md: file counts (33→201)
Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Workflow C: Design Spec Phases 3→4→5 (Run After A, Parallel with B)

### Task C1: Phase 3 — Defect Fixes

**Files:** ~20 files with known defects (see spec Section Phase 3)

- [ ] **Step C1.1: Fix 3.1 — Missing strongBuy/strongSell EMPTY_VALUE initialization (9 files)**

Files: `Oscillators/CCI_Safe.mq4`, `Oscillators/DeMarker_Safe.mq4`, `Oscillators/Momentum_Safe.mq4`, `Oscillators/OsMA_Safe.mq4`, `Oscillators/StochRSI_Safe.mq4`, `Oscillators/WilliamsR_Safe.mq4`, `Trend/DonchianChannel_Safe.mq4`, `Trend/KeltnerChannel_Safe.mq4`, `Custom/KDJ_Safe.mq4`

In each file's `start()` function, in the signal computation loop (`for (i = limit; i >= 1; i--)`), ensure these lines exist before signal assignments:
```mql4
strongBuy[i] = EMPTY_VALUE;
strongSell[i] = EMPTY_VALUE;
```

And in the bar[0] refresh section:
```mql4
strongBuy[0] = EMPTY_VALUE;
strongSell[0] = EMPTY_VALUE;
```

- [ ] **Step C1.2: Fix 3.2 — Asymmetric signals in BullsPower/BearsPower (2 files)**

For `Custom/BullsPower_Safe.mq4`: Add `strongSell[]` buffer declaration + SetIndexBuffer + SetIndexEmptyValue + init
For `Custom/BearsPower_Safe.mq4`: Add `strongBuy[]` buffer declaration + SetIndexBuffer + SetIndexEmptyValue + init

Update `#property indicator_buffers` by +1 in each file.

- [ ] **Step C1.3: Fix 3.3 — Inconsistent signal naming in MA_Safe (1 file)**

In `Trend/MA_Safe.mq4`:
- `buySignalBuffer[]` → `buySignal[]`
- `sellSignalBuffer[]` → `sellSignal[]`
- `strongSignal[]` → split into `strongBuy[]` + `strongSell[]`
- Update all `SetIndexBuffer` calls with new names
- Update `#property indicator_buffers` by +1 (split strongSignal into 2 buffers)

- [ ] **Step C1.4: Fix 3.4 — Missing SetIndexStyle for strong buffers (17 files)**

For each file that has `strongBuy[]`/`strongSell[]` buffers but no `SetIndexStyle` call for them, add after the last `SetIndexBuffer` for each strong buffer:
```mql4
SetIndexStyle(strongBuyIndex, DRAW_ARROW, STYLE_SOLID, 4, clrCyan);
SetIndexArrow(strongBuyIndex, 233);
SetIndexStyle(strongSellIndex, DRAW_ARROW, STYLE_SOLID, 4, clrDeepPink);
SetIndexArrow(strongSellIndex, 234);
```

- [ ] **Step C1.5: Verify Phase 3 fixes with mql4-validate**

```bash
cd "D:/MT4技术指标"
# Re-run all 6 rules on the ~20 Phase 3 files
# Confirm zero new violations
```

- [ ] **Step C1.6: Commit Phase 3**

```bash
cd "D:/MT4技术指标"
git add Oscillators/ Trend/ Custom/
git commit -m "fix: Phase 3 — defect fixes for EMPTY_VALUE, asymmetric signals, naming, SetIndexStyle

Fixes:
- 3.1: Add missing strongBuy/strongSell EMPTY_VALUE init (9 files)
- 3.2: Add missing buffer direction in BullsPower/BearsPower (2 files)
- 3.3: Standardize signal buffer naming in MA_Safe (1 file)
- 3.4: Add SetIndexStyle for strong buffers (17 files)
Co-Authored-By: Claude <noreply@anthropic.com>"
```

### Task C2: Phase 4 — Signal Grading Upgrade

**Files:** ~75 indicators across all directories

- [ ] **Step C2.1: Classify candidates by complexity tier**

For each candidate indicator, determine complexity:
- **Simple** (~30 files): Already has buy/sell signals, just needs strongBuy/strongSell buffers added
- **Medium** (~30 files): Needs signal logic extended for multi-condition confirmation
- **Complex** (~15 files): Multi-signal fusion, needs careful redesign while preserving existing behavior

- [ ] **Step C2.2: Create upgrade template for Simple tier**

For each Simple-tier indicator, apply this template:

**Buffers** (add after existing signal buffers):
```mql4
double strongBuy[], strongSell[];
```

**init()** (add after existing buffer setup):
```mql4
// Strong signal buffers
SetIndexBuffer(N, strongBuy);
SetIndexStyle(N, DRAW_ARROW, STYLE_SOLID, 4, clrCyan);
SetIndexArrow(N, 233);
SetIndexEmptyValue(N, EMPTY_VALUE);

SetIndexBuffer(N+1, strongSell);
SetIndexStyle(N+1, DRAW_ARROW, STYLE_SOLID, 4, clrDeepPink);
SetIndexArrow(N+1, 234);
SetIndexEmptyValue(N+1, EMPTY_VALUE);
```

**start() loop init** (add alongside existing signal init):
```mql4
strongBuy[i] = EMPTY_VALUE;
strongSell[i] = EMPTY_VALUE;
```

**Signal generation** (add BEFORE normal buy/sell signals — strong conditions checked first):
```mql4
// Strong buy: multi-condition confirmation
if (/* condition1 && condition2 && condition3 */) {
    strongBuy[i] = /* price */;
}
// Normal buy: single condition
else if (/* single condition */) {
    buySignal[i] = /* price */;
}
```

**bar[0] display** (add alongside existing bar[0] resets):
```mql4
strongBuy[0] = EMPTY_VALUE;
strongSell[0] = EMPTY_VALUE;
```

- [ ] **Step C2.3: Upgrade Simple-tier indicators (~30 files)**

Process each Simple-tier indicator:
1. Create isolated worktree
2. Apply the template (adjusting buffer indices per file)
3. Verify with mql4-reviewer agent
4. Commit and merge

- [ ] **Step C2.4: Upgrade Medium-tier indicators (~30 files)**

Process each Medium-tier indicator:
1. Read and analyze existing signal logic
2. Design strong signal conditions (multi-confirmation: cross + zone + divergence + K-line pattern)
3. Implement in worktree
4. Verify with mql4-reviewer agent
5. Commit and merge

- [ ] **Step C2.5: Upgrade Complex-tier indicators (~15 files)**

For each Complex-tier indicator:
1. Map all existing signal sources
2. Design signal strength scoring (weighted combination of signal sources)
3. Implement in worktree with careful attention to no-future-function
4. Adversarial verification: one agent upgrades, another tries to find issues
5. Commit and merge

- [ ] **Step C2.6: Verify Phase 4 with mql4-validate**

```bash
cd "D:/MT4技术指标"
# Run mql4-validate on all 75 upgraded files
# Confirm: zero CRITICAL, signal grading correctness passes
```

- [ ] **Step C2.7: Commit Phase 4 (per directory)**

```bash
cd "D:/MT4技术指标"
git add Oscillators/
git commit -m "feat: Phase 4a — signal grading upgrade for Oscillators directory
Co-Authored-By: Claude <noreply@anthropic.com>"

git add Trend/
git commit -m "feat: Phase 4b — signal grading upgrade for Trend directory
Co-Authored-By: Claude <noreply@anthropic.com>"

git add Volume/ BillWilliams/
git commit -m "feat: Phase 4c — signal grading upgrade for Volume + BillWilliams
Co-Authored-By: Claude <noreply@anthropic.com>"

git add Custom/
git commit -m "feat: Phase 4d — signal grading upgrade for Custom directory
Co-Authored-By: Claude <noreply@anthropic.com>"
```

### Task C3: Phase 5 — Style Unification

**Files:** ~40 files with style deviations

- [ ] **Step C3.1: Audit all files for style deviations**

```bash
cd "D:/MT4技术指标"
echo "=== Style Audit ==="
# Find non-standard arrow widths
echo "--- Arrow widths (non-2, non-4) ---"
grep -rn 'STYLE_SOLID,\s*[^24]' --include="*.mq4" .

echo "--- Non-standard arrow codes ---"
grep -rn 'SetIndexArrow.*\([^2][^3][^3]\|234[^)]*\|233[^)]*\)' --include="*.mq4" . | grep -v '233\|234'

echo "--- Non-standard buffer names ---"
grep -rn 'SignalBuffer\|signalBuffer\|BuyBuf\|SellBuf' --include="*.mq4" .
```

- [ ] **Step C3.2: Normalize arrow sizes**

For each file with non-standard arrow width:
- Width 1 or 3 → change to 2 (normal signals)
- Width != 4 for strong → change to 4

- [ ] **Step C3.3: Normalize arrow colors**

For each file with non-standard colors:
- Buy arrows: ensure `clrCyan` or equivalent blue
- Sell arrows: ensure `clrDeepPink` or equivalent red/pink

- [ ] **Step C3.4: Normalize buffer names**

For each file with non-standard names:
- `buySignalBuffer[]` → `buySignal[]`
- `sellSignalBuffer[]` → `sellSignal[]`
- `BuyBuf[]` → `buySignal[]`
- `SellBuf[]` → `sellSignal[]`

- [ ] **Step C3.5: Verify Phase 5 with mql4-validate + mql4-reviewer**

Run full validation. Run mql4-reviewer on each modified file. Confirm style consistency.

- [ ] **Step C3.6: Commit Phase 5**

```bash
cd "D:/MT4技术指标"
git add -A
git commit -m "style: Phase 5 — unify arrow sizes, colors, and buffer naming

Standardized: arrow width (2 normal / 4 strong), colors (Cyan/DeepPink), naming convention
Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Final Verification

- [ ] **Step F1: Full mql4-validate on ALL 201 files**

Run all 6 rules. Expected: zero CRITICAL, zero REQUIRED violations.

- [ ] **Step F2: Manual spot-check 5 random indicators**

Pick 5 indicators from different directories. Load in MT4 (if possible) or do deep static analysis. Verify:
- [ ] No bar[0] signal generation
- [ ] strong signals use correct colors/sizes
- [ ] Buffer count matches declaration

- [ ] **Step F3: Final status report**

Create `docs/automation-status-2026-06-13.md` with:
- Completed phases checklist
- Remaining issues (if any)
- Tested indicators list
- Git hooks status
- Claude automation status

- [ ] **Step F4: Final commit**

```bash
cd "D:/MT4技术指标"
git add docs/automation-status-2026-06-13.md
git commit -m "docs: automation completion status report

All 5 phases complete. 201 indicators validated. Automation layers active.
Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Execution Order Summary

```
1. Pre-Flight: Snapshot baseline
2. Workflow A (Task A1→A4): Scan all 201 files → Fix CRITICAL violations → Verify
   ⚠️ GATE: Zero CRITICAL violations before proceeding
3. Workflow B (Task B1→B5) ∥ Workflow C (Task C1→C3): Run in parallel
4. Final Verification (Task F1→F4): Full scan + spot-check + status report
```

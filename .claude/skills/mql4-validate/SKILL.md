---
name: mql4-validate
description: Validate all MQL4 indicators in the project against no-future-function rules and coding standards. Use after adding or modifying indicators, before committing changes, or when auditing the codebase.
---

# MQL4 Indicator Validator

Validates all `.mq4` indicator files against the project's core design rules: no future functions, no repainting signals, and correct buffer management.

## Validation Rules

### Rule 1: bar[0] Signal Generation (CRITICAL)
Signal buffers MUST only set EMPTY_VALUE on bar[0]. Signal assignments to bar[0] are a future-function violation.

```bash
grep -rn "Buffer\[0\].*=.*[^EMPTY_VALUE]" --include="*.mq4" .
```

### Rule 2: IndicatorCounted() Usage (REQUIRED)
Every indicator must use `IndicatorCounted()` to avoid redundant recalculation.

```bash
grep -L "IndicatorCounted" --include="*.mq4" ./*/
```

### Rule 3: Signal Buffers Use EMPTY_VALUE Sentinel (REQUIRED)
All arrow/signal buffers must call `SetIndexEmptyValue(i, EMPTY_VALUE)`.

```bash
for f in */*.mq4; do
  buffers=$(grep -c "SetIndexEmptyValue" "$f")
  declared=$(grep -oP "indicator_buffers \K\d+" "$f")
  echo "$f: declared=$declared, empty_values=$buffers"
done
```

### Rule 4: Buffer Count Consistency (REQUIRED)
`#property indicator_buffers N` must match the number of `SetIndexBuffer` calls.

```bash
for f in */*.mq4; do
  prop=$(grep -oP "indicator_buffers \K\d+" "$f")
  actual=$(grep -c "SetIndexBuffer" "$f")
  if [ "$prop" != "$actual" ]; then
    echo "MISMATCH: $f (declared=$prop, actual=$actual)"
  fi
done
```

### Rule 5: #include Path Validity (REQUIRED)
All `#include` directives must reference existing files.

```bash
for f in */*.mq4; do
  includes=$(grep -oP '#include "\K[^"]+' "$f")
  for inc in $includes; do
    base=$(dirname "$f")
    if [ ! -f "$base/$inc" ]; then
      echo "MISSING: $f includes $inc"
    fi
  done
done
```

### Rule 6: Strong Signal Buffers Have SetIndexStyle (REQUIRED)
Strong buy/sell buffers (strongBuy[], strongSell[]) must have `SetIndexStyle` configured with `DRAW_ARROW` and the correct arrow size/color.

```bash
for f in */*.mq4; do
  if grep -q 'strongBuy\|strongSell' "$f" 2>/dev/null; then
    has_style=$(grep -c 'SetIndexStyle.*strong' "$f" 2>/dev/null || echo "0")
    strong_count=$(grep -c 'strongBuy\[\|strongSell\[' "$f" 2>/dev/null || echo "0")
    if [ "$has_style" -lt "$strong_count" ] 2>/dev/null; then
      echo "MISSING SetIndexStyle for strong buffers: $f (has=$has_style, need=$strong_count)"
    fi
  fi
done
```

## Usage

Run the skill with `/mql4-validate` to execute all rules and get a compliance report. The skill outputs:
- Per-rule pass/fail counts
- List of files with violations
- Overall compliance percentage

## Target

- **CRITICAL violations** (Rule 1, 4): Must be fixed before any indicator is loaded in MT4
- **WARNING violations** (Rule 2, 3, 5): Should be fixed for consistency but won't break compilation

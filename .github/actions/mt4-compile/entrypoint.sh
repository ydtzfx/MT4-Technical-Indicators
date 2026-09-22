#!/usr/bin/env bash
set -uo pipefail

paths_input="${1:-}"
expected_count="${2:-0}"
report_dir="${3:-artifacts/p0-5/compile}"
include_dir="${4:-.}"

compiler_image="docker.io/mhriemers/metatrader-4@sha256:ed6c3abb2188ac178f183e30bd03cb85c7f2bf8abebfdffa70c070ff2fb1ad74"
wine_image="docker.io/mhriemers/wine@sha256:88fe77b8ad68b4a3a09a9e858aaee6d33aa07533c99da47c7d88fd76e7edac58"
compiler_sha256="$(sha256sum /metaeditor.exe | awk '{print $1}')"

mkdir -p "$report_dir/logs" "$report_dir/results"

files=()
while IFS= read -r spec; do
  [[ -z "$spec" ]] && continue
  if [[ -d "$spec" ]]; then
    while IFS= read -r f; do files+=("$f"); done < <(find "$spec" -type f -name '*.mq4' -print | sort)
  elif [[ -f "$spec" ]]; then
    files+=("$spec")
  else
    while IFS= read -r f; do [[ -n "$f" ]] && files+=("$f"); done < <(compgen -G "$spec" || true)
  fi
done <<< "$paths_input"

if [[ ${#files[@]} -gt 0 ]]; then
  mapfile -t files < <(printf '%s\n' "${files[@]}" | sort -u)
fi

discovered=${#files[@]}
passed=0
failed=0
errors_total=0
warnings_total=0
parser_failures=0

compile_one() {
  local f="$1"
  local log="${f%.*}.log"
  local output="${f%.*}.ex4"
  local safe status errors warnings content summary
  safe="$(echo "$f" | tr '/\\ ' '___')"

  rm -f "$log" "$output"
  echo "[$f] Compiling with locked MT4 MetaEditor ($compiler_sha256)..."
  wine /metaeditor.exe "/log" "/inc:$include_dir" "/compile:$f" >/dev/null 2>&1 || true

  status="FAIL"
  errors=998
  warnings=0

  if [[ -f "$log" ]]; then
    cp "$log" "$report_dir/logs/$safe.log"
    content="$(iconv -f utf-16le -t utf-8 -c "$log" | sed -r '/^[[:space:]]+$/d')"
    summary="$(printf '%s\n' "$content" | sed -rn 's/^[Rr]esult:? ([[:digit:]]+) errors?, ([[:digit:]]+) warnings?.*$/\1 \2/p' | tail -n 1)"
    if [[ -n "$summary" ]]; then
      read -r errors warnings <<< "$summary"
      if [[ "$errors" -eq 0 && -f "$output" ]]; then
        status="PASS"
      fi
    else
      errors=997
      parser_failures=$((parser_failures + 1))
    fi
  else
    parser_failures=$((parser_failures + 1))
  fi

  errors_total=$((errors_total + errors))
  warnings_total=$((warnings_total + warnings))
  if [[ "$status" == "PASS" ]]; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi

  cat > "$report_dir/results/$safe.compile.json" <<JSON
{"file":"$f","status":"$status","errors":$errors,"warnings":$warnings,"compiler_sha256":"$compiler_sha256","compiler_image":"$compiler_image","wine_image":"$wine_image"}
JSON

  echo "[$f] $status — $errors errors, $warnings warnings"
}

if [[ "$discovered" -eq "$expected_count" ]]; then
  for f in "${files[@]}"; do
    compile_one "$f"
  done
else
  failed=$((failed + 1))
fi

overall="FAIL"
if [[ "$discovered" -eq "$expected_count" && "$passed" -eq "$expected_count" && "$failed" -eq 0 && "$errors_total" -eq 0 && "$parser_failures" -eq 0 ]]; then
  overall="PASS"
fi

cat > "$report_dir/compile-report.json" <<JSON
{
  "status":"$overall",
  "expected_count":$expected_count,
  "discovered_count":$discovered,
  "passed_count":$passed,
  "failed_count":$failed,
  "errors_total":$errors_total,
  "warnings_total":$warnings_total,
  "parser_failures":$parser_failures,
  "compiler_sha256":"$compiler_sha256",
  "compiler_image":"$compiler_image",
  "wine_image":"$wine_image"
}
JSON

cat > "$report_dir/compile-report.md" <<MD
# MT4 MetaEditor compile report

- Status: **$overall**
- Expected: **$expected_count**
- Discovered: **$discovered**
- Passed: **$passed**
- Failed: **$failed**
- Errors: **$errors_total**
- Warnings: **$warnings_total**
- Parser failures: **$parser_failures**
- MetaEditor SHA256: `$compiler_sha256`
- MT4 image: `$compiler_image`
- Wine image: `$wine_image`
MD

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  cat "$report_dir/compile-report.md" >> "$GITHUB_STEP_SUMMARY"
fi

if [[ "$overall" != "PASS" ]]; then
  exit 1
fi

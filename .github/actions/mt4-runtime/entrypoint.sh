#!/usr/bin/env bash
set -euo pipefail
history_dir="/github/workspace/${1}"
output_dir="/github/workspace/${2}"
mt4="/root/.wine/drive_c/Program Files/MetaTrader 4"

mkdir -p "$output_dir" \
  "$mt4/MQL4/Indicators/Trend" "$mt4/MQL4/Indicators/Oscillators" "$mt4/MQL4/Indicators/Custom" \
  "$mt4/MQL4/Experts" "$mt4/history/default" "$mt4/tester/files"

cp /github/workspace/Trend/MA_Safe.ex4 "$mt4/MQL4/Indicators/Trend/"
cp /github/workspace/Oscillators/RSI_Safe.ex4 "$mt4/MQL4/Indicators/Oscillators/"
cp /github/workspace/Oscillators/MACD_Safe.ex4 "$mt4/MQL4/Indicators/Oscillators/"
cp /github/workspace/Oscillators/Stochastic_Safe.ex4 "$mt4/MQL4/Indicators/Oscillators/"
cp /github/workspace/Trend/Ichimoku_Safe.ex4 "$mt4/MQL4/Indicators/Trend/"
cp /github/workspace/Custom/MTF_RSI_Safe.ex4 "$mt4/MQL4/Indicators/Custom/"
cp /github/workspace/Custom/Backtest_Safe.ex4 "$mt4/MQL4/Indicators/Custom/"
cp /github/workspace/Tests/P0_5_NoRepaintProbe.ex4 "$mt4/MQL4/Experts/P0_5_NoRepaintProbe.ex4"
cp "$history_dir"/*.hst "$mt4/history/default/"

rm -f "$mt4/tester/files/p0_5_no_repaint.csv"
rm -f "$mt4/p0_5_report.htm" "$mt4/p0_5_report.gif"

cat > "$mt4/p0_5.ini" <<'INI'
TestExpert=P0_5_NoRepaintProbe
TestSymbol=EURUSD
TestPeriod=H1
TestModel=2
TestSpread=10
TestOptimization=false
TestDateEnable=false
TestReport=p0_5_report
TestReplaceReport=true
TestShutdownTerminal=true
TestVisualEnable=false
INI

echo "=== MT4 runtime ==="
ls -l "$mt4/terminal.exe" "$mt4/MQL4/Experts/P0_5_NoRepaintProbe.ex4"
echo "=== injected histories ==="
ls -lh "$mt4/history/default"/EURUSD*.hst

cfg="$(winepath -w "$mt4/p0_5.ini")"
set +e
timeout 900 wine "$mt4/terminal.exe" /portable "/config:$cfg"
terminal_rc=$?
set -e
echo "terminal exit code: $terminal_rc"

csv="$(find "$mt4" /root/.wine -type f -name 'p0_5_no_repaint.csv' -print -quit 2>/dev/null || true)"
if [[ -n "$csv" && -f "$csv" ]]; then
  cp "$csv" "$output_dir/p0_5_no_repaint.csv"
fi
report="$(find "$mt4" -type f -name 'p0_5_report*.htm' -print -quit 2>/dev/null || true)"
if [[ -n "$report" && -f "$report" ]]; then cp "$report" "$output_dir/strategy-tester-report.htm"; fi
find "$mt4/tester" -type f -name '*.log' -exec cp {} "$output_dir/" \; 2>/dev/null || true

cat > "$output_dir/runtime-execution.json" <<JSON
{"terminal_exit_code":$terminal_rc,"csv_found":$([[ -f "$output_dir/p0_5_no_repaint.csv" ]] && echo true || echo false),"terminal_sha256":"$(sha256sum "$mt4/terminal.exe" | awk '{print $1}')"}
JSON

if [[ ! -f "$output_dir/p0_5_no_repaint.csv" ]]; then
  echo "Strategy Tester did not produce p0_5_no_repaint.csv" >&2
  exit 2
fi

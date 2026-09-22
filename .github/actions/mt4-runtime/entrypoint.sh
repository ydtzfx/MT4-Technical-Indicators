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

printf '%s\r\n' \
  'ExpertsEnable=true' \
  'TestExpert=P0_5_NoRepaintProbe' \
  'TestSymbol=EURUSD' \
  'TestPeriod=H1' \
  'TestModel=2' \
  'TestSpread=10' \
  'TestOptimization=false' \
  'TestDateEnable=true' \
  'TestFromDate=2024.01.10' \
  'TestToDate=2024.01.28' \
  'TestReport=p0_5_report' \
  'TestReplaceReport=true' \
  'TestShutdownTerminal=true' \
  'TestVisualEnable=false' \
  > "$mt4/p0_5.ini"

echo "=== MT4 runtime ==="
ls -l "$mt4/terminal.exe" "$mt4/MQL4/Experts/P0_5_NoRepaintProbe.ex4"
echo "=== injected histories ==="
ls -lh "$mt4/history/default"/EURUSD*.hst
echo "=== history/default metadata ==="
find "$mt4/history/default" -maxdepth 1 -type f -printf '%f %s bytes\n' | sort | head -100

cfg="$(winepath -w "$mt4/p0_5.ini")"
echo "strategy tester config: $cfg"

export DISPLAY=:99
Xvfb :99 -screen 0 1366x768x24 +extension GLX +extension RANDR +extension RENDER >/tmp/p05-xvfb.log 2>&1 &
xvfb_pid=$!
trap 'kill "$xvfb_pid" >/dev/null 2>&1 || true' EXIT
sleep 2

set +e
timeout 300 bash -c 'wine "$1" /portable "/config:$2" & wineserver -w' _ "$mt4/terminal.exe" "$cfg"
terminal_rc=$?
set -e
echo "terminal/wineserver exit code: $terminal_rc"
echo "=== Xvfb log ==="
tail -n 100 /tmp/p05-xvfb.log || true

csv="$(find "$mt4" /root/.wine -type f -name 'p0_5_no_repaint.csv' -print -quit 2>/dev/null || true)"
if [[ -n "$csv" && -f "$csv" ]]; then
  cp "$csv" "$output_dir/p0_5_no_repaint.csv"
fi
report="$(find "$mt4" -type f -name 'p0_5_report*.htm' -print -quit 2>/dev/null || true)"
if [[ -n "$report" && -f "$report" ]]; then cp "$report" "$output_dir/strategy-tester-report.htm"; fi
find "$mt4/tester" -type f -name '*.log' -exec cp {} "$output_dir/" \; 2>/dev/null || true
find "$mt4/logs" -type f -name '*.log' -exec cp {} "$output_dir/" \; 2>/dev/null || true

echo "=== tester/runtime files ==="
find "$mt4/tester" -maxdepth 3 -type f -printf '%p %s bytes\n' 2>/dev/null | sort || true
echo "=== tester journals (tail) ==="
while IFS= read -r log; do
  echo "--- $log"
  tail -n 80 "$log" || true
done < <(find "$mt4/tester" -type f -name '*.log' -print 2>/dev/null | sort)
echo "=== terminal journals (tail) ==="
while IFS= read -r log; do
  echo "--- $log"
  tail -n 50 "$log" || true
done < <(find "$mt4/logs" -type f -name '*.log' -print 2>/dev/null | sort)

cat > "$output_dir/runtime-execution.json" <<JSON
{"terminal_exit_code":$terminal_rc,"csv_found":$([[ -f "$output_dir/p0_5_no_repaint.csv" ]] && echo true || echo false),"terminal_sha256":"$(sha256sum "$mt4/terminal.exe" | awk '{print $1}')"}
JSON

if [[ ! -f "$output_dir/p0_5_no_repaint.csv" ]]; then
  echo "Strategy Tester did not produce p0_5_no_repaint.csv" >&2
  exit 2
fi

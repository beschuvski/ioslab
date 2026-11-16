#!/usr/bin/env bash
#
# ios-sim.sh - drive the iOS Simulator on a macOS runner (or a Mac).
#
#   ios-sim.sh resolve
#       Print the UDID of a usable, booted iPhone simulator (boots none).
#
#   ios-sim.sh run --app <path/to/App.app> --bundle <bundle-id> --out <dir> [--name <prefix>]
#       Boot the simulator, install the app, launch it, capture light/dark
#       screenshots at native resolution.
#
# Requires: macOS + Xcode command line tools (xcrun simctl).
set -euo pipefail

log() { printf '[ios-sim] %s\n' "$*"; }

resolve_device() {
  python3 - <<'PY'
import json, re, subprocess, sys

raw = subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "-j"])
devices = json.loads(raw)["devices"]

def version_key(runtime):
    m = re.search(r"iOS-(\d+)(?:-(\d+))?", runtime)
    return (int(m.group(1)), int(m.group(2) or 0)) if m else (0, 0)

booted = [d for rt in devices for d in devices[rt] if d.get("state") == "Booted"]
if booted:
    print(booted[0]["udid"])
    sys.exit(0)

runtimes = sorted(devices.keys(), key=version_key, reverse=True)
for rt in runtimes:
    for d in devices[rt]:
        if d["name"].startswith("iPhone"):
            print(d["udid"])
            sys.exit(0)

for rt in runtimes:
    if devices[rt]:
        print(devices[rt][0]["udid"])
        sys.exit(0)

sys.stderr.write("no iOS simulator available\n")
sys.exit(1)
PY
}

cmd_resolve() {
  resolve_device
}

cmd_run() {
  local app="" bundle="" out="artifacts/screenshots" name="ios"
  while [ $# -gt 0 ]; do
    case "$1" in
      --app) app="$2"; shift 2 ;;
      --bundle) bundle="$2"; shift 2 ;;
      --out) out="$2"; shift 2 ;;
      --name) name="$2"; shift 2 ;;
      *) echo "unknown argument: $1" >&2; exit 2 ;;
    esac
  done
  [ -n "$app" ] || { echo "--app is required" >&2; exit 2; }
  [ -n "$bundle" ] || { echo "--bundle is required" >&2; exit 2; }
  [ -d "$app" ] || { echo "app bundle not found: $app" >&2; exit 2; }

  local udid
  udid="$(resolve_device)"
  log "device: $udid"

  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b

  # A clean, readable status bar makes screenshots comparable over time.
  xcrun simctl status_bar "$udid" override \
    --time "9:41" --batteryState charged --batteryLevel 100 \
    --wifiBars 3 --cellularBars 4 2>/dev/null || true

  xcrun simctl terminate "$udid" "$bundle" 2>/dev/null || true
  xcrun simctl install "$udid" "$app"
  xcrun simctl ui "$udid" appearance light 2>/dev/null || true

  mkdir -p "$out"
  log "launching $bundle"
  if ! xcrun simctl launch "$udid" "$bundle" >/dev/null 2>&1; then
    log "launch failed; last 40 lines of the app log:"
    xcrun simctl spawn "$udid" log show --last 2m --style compact 2>/dev/null \
      | grep -iE 'Runner|NativeLab|fatal|crash' | tail -n 40 || true
    exit 1
  fi
  sleep 4

  local shot="$out/$name-light.png"
  xcrun simctl io "$udid" screenshot "$shot"

  xcrun simctl ui "$udid" appearance dark 2>/dev/null || true
  sleep 2
  xcrun simctl io "$udid" screenshot "$out/$name-dark.png"
  xcrun simctl ui "$udid" appearance light 2>/dev/null || true

  log "screenshots:"
  ls -l "$out"
}

case "${1:-}" in
  resolve) shift; cmd_resolve ;;
  run) shift; cmd_run "$@" ;;
  *) echo "usage: $0 {resolve|run --app PATH --bundle ID --out DIR [--name PREFIX]}" >&2; exit 2 ;;
esac

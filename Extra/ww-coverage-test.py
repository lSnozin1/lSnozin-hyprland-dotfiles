#!/usr/bin/env python3
"""Automated coverage test for the waywallen auto-pause (Hyprland 0.57, Lua dispatchers).

Spawns placeholder kitty windows on temporary workspaces, toggles tiling/floating,
resizes them and records after each step: per-monitor coverage (same formula as the
hyprctl wrapper) and which waywallen renderer processes are alive. Writes a JSON report.
Your own windows are not touched; workspaces and focus are restored at the end.
"""
import argparse
import json
import signal
import subprocess
import sys
import time

HYPRCTL = "/usr/bin/hyprctl"  # real binary, bypasses the wrapper on purpose
NOT_RENDERERS = {"waywallen", "waywallen-ui", "waywallen-layer"}
TEST_WS_TARGET = "99"
TEST_WS_OTHER = "98"
SWEEP = [30, 50, 60, 70, 80, 90, 95]

errors = []
procs = {}


def dispatch(expr):
    r = subprocess.run([HYPRCTL, "dispatch", expr], capture_output=True, text=True)
    out = (r.stdout + r.stderr).strip()
    if out != "ok":
        errors.append({"expr": expr, "out": out})
    return out


def hj(cmd):
    return json.loads(subprocess.check_output([HYPRCTL, "-j", cmd], text=True))


def sel(cls):
    return f'"class:^{cls}$"'


def goto(monitor, ws):
    dispatch(f'hl.dsp.focus({{ monitor = "{monitor}" }})')
    dispatch(f'hl.dsp.focus({{ workspace = "{ws}" }})')


def find_client(cls):
    for c in hj("clients"):
        if c["class"] == cls:
            return c
    return None


def spawn(cls):
    procs[cls] = subprocess.Popen(["kitty", "--class", cls, "sleep", "3600"],
                                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    for _ in range(50):
        time.sleep(0.1)
        if find_client(cls):
            return True
    errors.append({"expr": f"spawn {cls}", "out": "window did not appear"})
    return False


def close(cls):
    p = procs.pop(cls, None)
    if p:
        p.terminate()
        try:
            p.wait(timeout=3)
        except subprocess.TimeoutExpired:
            p.kill()


def resize_to(cls, w, h):
    """Try the window selector first, then focus + resize the active window."""
    for attempt in ("selector", "focus"):
        if attempt == "selector":
            dispatch(f'hl.dsp.window.resize({{ x = {w}, y = {h}, relative = false, window = {sel(cls)} }})')
        else:
            dispatch(f'hl.dsp.focus({{ window = {sel(cls)} }})')
            dispatch(f'hl.dsp.window.resize({{ x = {w}, y = {h}, relative = false }})')
        time.sleep(0.4)
        c = find_client(cls)
        if c and abs(c["size"][0] - w) <= 2 and abs(c["size"][1] - h) <= 2:
            return attempt
    return "failed"


def coverage(mons, clients):
    """Same rule as the wrapper: per visible layer, max(tiled area sum, biggest floating)."""
    res = {}
    for m in mons:
        total = m["width"] * m["height"]
        layers = [m["activeWorkspace"]["address"]]
        special = (m.get("specialWorkspace") or {}).get("address", "")
        if special:
            layers.append(special)
        best = 0
        for addr in layers:
            ws = [c for c in clients if c["mapped"] and not c["hidden"]
                  and c["monitor"] == m["id"] and c["workspace"]["address"] == addr]
            tiled = sum(c["size"][0] * c["size"][1] for c in ws if not c["floating"])
            floating = max([c["size"][0] * c["size"][1] for c in ws if c["floating"]], default=0)
            best = max(best, tiled, floating)
        res[m["name"]] = round(100 * best / total, 1)
    return res


def waywallen_procs():
    out = subprocess.run(["ps", "-eo", "pid=,comm="], capture_output=True, text=True).stdout
    found = []
    for line in out.splitlines():
        pid, _, comm = line.strip().partition(" ")
        comm = comm.strip()
        if comm.startswith("waywallen"):
            found.append((int(pid), comm))
    return found


def measure(report, label, settle, note=None):
    time.sleep(settle)
    samples = []
    for _ in range(3):
        found = waywallen_procs()
        samples.append(sorted(c for _, c in found if c not in NOT_RENDERERS))
        time.sleep(1)
    mons, clients = hj("monitors"), hj("clients")
    entry = {
        "label": label,
        "coverage_pct": coverage(mons, clients),
        "renderers": samples[-1],
        "paused": len(samples[-1]) == 0,
        "stable": all(s == samples[0] for s in samples),
        "all_waywallen_comms": sorted({c for _, c in waywallen_procs()}),
        "test_windows": [{"class": c["class"], "monitor": c["monitor"], "floating": c["floating"],
                          "size": c["size"], "fullscreen": c["fullscreen"]}
                         for c in clients if c["class"].startswith("wwtest-")],
    }
    if note:
        entry["note"] = note
    report["steps"].append(entry)
    print(f'{label:28} cov={entry["coverage_pct"]} renderers={len(entry["renderers"])} '
          f'paused={entry["paused"]} stable={entry["stable"]}', flush=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--monitor", help="target monitor name (default: focused one)")
    ap.add_argument("--settle", type=float, default=3.5, help="seconds to wait after each change")
    ap.add_argument("--out", default="/tmp/ww-coverage-test.json")
    args = ap.parse_args()

    mons = hj("monitors")
    if any((m.get("specialWorkspace") or {}).get("address") for m in mons):
        sys.exit("A special workspace is visible on a monitor. Hide it and run again.")
    focused = next((m for m in mons if m.get("focused")), mons[0])
    target = next((m for m in mons if m["name"] == args.monitor), focused) if args.monitor else focused
    others = [m for m in mons if m["name"] != target["name"]]
    other = others[0] if others else None
    initial = {m["name"]: m["activeWorkspace"]["name"] for m in mons}
    mw, mh = target["width"], target["height"]
    report = {"target": target["name"], "other": other["name"] if other else None, "steps": []}

    def restore(*_):
        for cls in list(procs):
            close(cls)
        time.sleep(0.5)
        for name, ws in initial.items():
            goto(name, ws)
        goto(focused["name"], initial[focused["name"]])

    signal.signal(signal.SIGINT, lambda *a: (restore(), sys.exit(1)))
    try:
        if other:
            goto(other["name"], TEST_WS_OTHER)
        goto(target["name"], TEST_WS_TARGET)
        s = args.settle

        measure(report, "baseline_empty", s + 2)
        spawn("wwtest-1")
        measure(report, "target_tiled_1", s)
        spawn("wwtest-2")
        measure(report, "target_tiled_2_side_by_side", s)
        close("wwtest-2")
        dispatch(f'hl.dsp.window.float({{ action = "set", window = {sel("wwtest-1")} }})')
        for pct in SWEEP:
            h = round(mh * pct / 100)
            method = resize_to("wwtest-1", mw, h)
            measure(report, f"target_float_{pct}pct", s, note=f"resize:{method}")
        dispatch(f'hl.dsp.window.float({{ action = "unset", window = {sel("wwtest-1")} }})')
        measure(report, "target_back_to_tiled", s)
        close("wwtest-1")
        measure(report, "target_empty_again", s)
        if other:
            goto(other["name"], TEST_WS_OTHER)
            spawn("wwtest-3")
            measure(report, "other_only_tiled", s)
            goto(target["name"], TEST_WS_TARGET)
            spawn("wwtest-4")
            measure(report, "both_tiled", s)
            close("wwtest-3")
            measure(report, "target_only_tiled", s)
    finally:
        restore()
    report["dispatch_errors"] = errors
    with open(args.out, "w") as f:
        json.dump(report, f, indent=1)
    print(f"\nReport written to {args.out} ({len(errors)} dispatch errors)")


if __name__ == "__main__":
    main()
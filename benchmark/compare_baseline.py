#!/usr/bin/env python3
"""Compare a baseline.json written by record_baseline.jl against a reference.

Usage: python3 benchmark/compare_baseline.py REFERENCE.json NEW.json [--rtol 1e-12]

Numbers are compared with a relative tolerance (default: exact up to 1e-12).
Timings are reported as ratios and never fail the comparison.
"""
import json
import math
import sys


def walk(ref, new, path, rtol, mismatches):
    if isinstance(ref, dict) and isinstance(new, dict):
        for key in sorted(set(ref) | set(new)):
            if key in ("timings_seconds", "hostname", "configuration", "threads",
                       "julia_version"):
                continue
            if key not in ref or key not in new:
                mismatches.append(f"{path}/{key}: missing on one side")
                continue
            walk(ref[key], new[key], f"{path}/{key}", rtol, mismatches)
    elif isinstance(ref, list) and isinstance(new, list):
        if len(ref) != len(new):
            mismatches.append(f"{path}: length {len(ref)} != {len(new)}")
            return
        for i, (a, b) in enumerate(zip(ref, new)):
            walk(a, b, f"{path}[{i}]", rtol, mismatches)
    elif isinstance(ref, (int, float)) and isinstance(new, (int, float)):
        if not math.isclose(ref, new, rel_tol=rtol, abs_tol=0.0) and ref != new:
            mismatches.append(f"{path}: {ref!r} != {new!r}")
    elif ref != new:
        mismatches.append(f"{path}: {ref!r} != {new!r}")


def main(argv):
    if len(argv) < 3:
        print(__doc__)
        return 2
    rtol = float(argv[argv.index("--rtol") + 1]) if "--rtol" in argv else 1e-12
    with open(argv[1]) as f:
        ref = json.load(f)
    with open(argv[2]) as f:
        new = json.load(f)

    mismatches = []
    walk(ref, new, "", rtol, mismatches)

    print(f"reference: {ref.get('hostname')} threads={ref.get('threads')}")
    print(f"new:       {new.get('hostname')} threads={new.get('threads')}")
    print(f"{'timing':45s} {'ref [s]':>9s} {'new [s]':>9s} {'speedup':>8s}")
    ref_t, new_t = ref.get("timings_seconds", {}), new.get("timings_seconds", {})
    for key in sorted(set(ref_t) & set(new_t)):
        speedup = ref_t[key] / new_t[key] if new_t[key] > 0 else float("inf")
        print(f"{key:45s} {ref_t[key]:9.3f} {new_t[key]:9.3f} {speedup:8.2f}")

    if mismatches:
        print(f"\nVALUES DIFFER ({len(mismatches)}):")
        for line in mismatches[:50]:
            print("  " + line)
        return 1
    print("\nVALUES MATCH")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

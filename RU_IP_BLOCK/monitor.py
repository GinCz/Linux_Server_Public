#!/usr/bin/env python3
"""Compare public TCP reachability from Russian and foreign Check-Host nodes."""

import argparse
import datetime as dt
import ipaddress
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

API = "https://check-host.net"
UNKNOWN = "NO_DATA"


def api_get(path):
    request = urllib.request.Request(API + path, headers={
        "Accept": "application/json", "User-Agent": "Mozilla/5.0 RU_IP_BLOCK/1.0"})
    with urllib.request.urlopen(request, timeout=20) as response:
        raw = response.read(2_000_001)
    if len(raw) > 2_000_000:
        raise ValueError("API response exceeds size limit")
    return json.loads(raw)


def check_rkn(ip):
    try:
        request = urllib.request.Request("https://reestr.rublacklist.net/api/v3/ips/", headers={
            "Accept": "application/json", "User-Agent": "Mozilla/5.0 RU_IP_BLOCK/1.0"})
        with urllib.request.urlopen(request, timeout=10) as response:
            raw = response.read(5_000_000)
            return f'"{ip}"' in raw.decode('utf-8')
    except Exception:
        return False


def validate_target(target):
    if not isinstance(target, dict):
        raise ValueError("Each target must be an object")
    name = target.get("name", "")
    if not isinstance(name, str) or not re.fullmatch(r"[A-Za-z0-9_.-]{1,64}", name):
        raise ValueError("Target name must contain 1-64 ASCII letters, digits, _, . or -")
    address = ipaddress.ip_address(target.get("ip", ""))
    if address.version != 4 or not address.is_global:
        raise ValueError("A complete public IPv4 address is required")
    port = target.get("port")
    if type(port) is not int or not 1 <= port <= 65535:
        raise ValueError("TCP port must be an integer from 1 to 65535")
    command = target.get("probe_command")
    if command is not None and (not isinstance(command, list) or not command
                                or not all(isinstance(x, str) and x for x in command)):
        raise ValueError("probe_command must be a nonempty argument array")
    return dict(target, ip=str(address))


def select_nodes(catalog):
    selected = {}
    for russian, limit in ((True, 3), (False, 3)):
        seen = set()
        for name, info in sorted(catalog.items()):
            location = info.get("location", [])
            asn = str(info.get("asn", "")).strip()
            if not location or not asn or (location[0] == "ru") != russian or asn in seen:
                continue
            if not re.fullmatch(r"[a-z0-9.-]+", name):
                continue
            selected[name] = {"country": location[0], "asn": asn}
            seen.add(asn)
            if len(seen) == limit:
                break
    return selected


def parse_tcp(value):
    if not isinstance(value, list) or not value or not isinstance(value[0], dict):
        return UNKNOWN
    item = value[0]
    if item.get("error"):
        return "FAIL"
    if isinstance(item.get("time"), (float, int)) and item["time"] >= 0:
        return "OK"
    return UNKNOWN


def measure(host, nodes, get=api_get, sleep=time.sleep, polls=10):
    if not nodes:
        return {}, None
    query = urllib.parse.urlencode([("host", host)] + [("node", n) for n in nodes])
    started = get("/check-tcp?" + query)
    request_id = str(started.get("request_id", ""))
    if started.get("ok") != 1 or not re.fullmatch(r"[A-Za-z0-9_-]+", request_id):
        raise ValueError("API did not accept the measurement")
    actual = started.get("nodes", {})
    results = {}
    for _ in range(polls):
        sleep(3)
        results = get("/check-result/" + request_id)
        if not isinstance(results, dict):
            raise ValueError("Invalid measurement response")
        if all(results.get(n) is not None for n in nodes if n in actual):
            break
    return {n: parse_tcp(results.get(n)) if n in actual else UNKNOWN for n in nodes}, request_id


def classify(rows):
    ru = [r for r in rows if r["country"] == "ru"]
    foreign = [r for r in rows if r["country"] != "ru"]
    good = [r for r in ru if r["target"] == "OK"]
    bad = [r for r in ru if r["target"] == "FAIL" and r["control"] == "OK"]
    foreign_good = any(r["target"] == "OK" for r in foreign)
    if bad and foreign_good:
        return "RU_RESTRICTION_SUSPECTED" if len({r["asn"] for r in bad}) >= 2 else "RU_NETWORK_FAILURE"
    if good and not bad:
        if len(good) == len(ru) and len({r["asn"] for r in good}) >= 2 and foreign_good:
            return "TCP_REACHABLE"
        return "PARTIAL_DATA"
    if bad and any(r["target"] == "FAIL" and r["control"] == "OK" for r in foreign) and not foreign_good:
        return "TARGET_OR_ROUTE_FAILURE"
    return "INCONCLUSIVE"


def transition(previous, status, threshold):
    count = previous.get("count", 0) + 1 if previous.get("candidate") == status else 1
    stable = previous.get("stable")
    changed = count >= threshold and status != stable
    return {"candidate": status, "count": count, "stable": status if changed else stable}, changed


def probe(command):
    if not command:
        return "NOT_CONFIGURED"
    try:
        result = subprocess.run(command, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                                stderr=subprocess.DEVNULL, timeout=45, check=False)
        return {0: "PASS", 1: "FAIL"}.get(result.returncode, UNKNOWN)
    except (OSError, subprocess.TimeoutExpired):
        return UNKNOWN


def atomic_json(path, value):
    temporary = path.with_suffix(path.suffix + ".tmp")
    with temporary.open("w", encoding="utf-8", newline="\n") as output:
        json.dump(value, output, ensure_ascii=False, indent=2)
        output.write("\n")
    os.replace(temporary, path)


def append_history(path, value):
    if path.exists() and path.stat().st_size >= 5_000_000:
        os.replace(path, path.with_suffix(".jsonl.1"))
    with path.open("a", encoding="utf-8", newline="\n") as output:
        output.write(json.dumps(value, ensure_ascii=False) + "\n")


def run_cycle(targets, control_host, directory, threshold, state):
    timestamp = dt.datetime.now(dt.timezone.utc).isoformat()
    report = {"timestamp": timestamp, "scope": "public TCP reachability, not VPN functionality", "targets": []}
    try:
        nodes = select_nodes(api_get("/nodes/hosts")["nodes"])
        controls, control_id = measure(control_host, nodes)
        setup_error = None
    except (OSError, ValueError, KeyError, TypeError) as error:
        nodes, controls, control_id = {}, {}, None
        setup_error = type(error).__name__
    for target in targets:
        request_id, error_name = None, setup_error
        try:
            results, request_id = measure("{}:{}".format(target["ip"], target["port"]), nodes)
        except (OSError, ValueError, KeyError, TypeError) as error:
            results, error_name = {}, type(error).__name__
        rows = [dict(info, node=n, target=results.get(n, UNKNOWN), control=controls.get(n, UNKNOWN))
                for n, info in nodes.items()]
        status = classify(rows)
        key = "{}|{}|{}|{}".format(target["name"], target["ip"], target["port"], control_host)
        next_state, changed = transition(state.get(key, {}), status, threshold)
        state[key] = next_state
        item = {"name": target["name"], "ip": target["ip"], "port": target["port"],
                "status": status, "confirmed_status": next_state["stable"],
                "consecutive": next_state["count"], "changed": changed, "nodes": rows,
                "request_id": request_id, "control_request_id": control_id,
                "local_probe": probe(target.get("probe_command")), "api_error": error_name,
                "rkn_listed": check_rkn(target["ip"])}
        report["targets"].append(item)
        print("{} {} {}:{} {} ({}/{}) local_probe={} rkn_listed={}".format(
            timestamp, target["name"], target["ip"], target["port"], status,
            next_state["count"], threshold, item["local_probe"], item["rkn_listed"]), flush=True)
        for row in rows:
            print("  {node:30} {country:2} {asn:12} target={target:7} control={control}".format(**row))
        if error_name:
            print("  API unavailable or invalid response: " + error_name)
        if changed:
            print("  EVENT: stable status changed to " + status, flush=True)
    atomic_json(directory / "latest.json", report)
    append_history(directory / "history.jsonl", report)
    atomic_json(directory / "state.json", {"updated": time.time(), "targets": state})
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, help="Local JSON configuration; never commit real targets")
    parser.add_argument("--ip", help="Full public IPv4 address")
    parser.add_argument("--port", type=int, help="Existing TCP listening port, not a UDP port")
    parser.add_argument("--name", default="vpn-server")
    parser.add_argument("--public-checks", action="store_true", help="Allow disclosure of target IP/port to Check-Host")
    parser.add_argument("--watch", action="store_true", help="Repeat until Ctrl+C; foreground only")
    parser.add_argument("--interval", type=int, default=300, help="Seconds between cycles, minimum 300")
    parser.add_argument("--threshold", type=int, default=3, help="Consecutive cycles before a status-change event")
    parser.add_argument("--output", type=Path, default=Path("RU_IP_BLOCK_DATA"))
    parser.add_argument("--control", default="example.com:443", help="Known reachable public TCP endpoint")
    args = parser.parse_args()
    if args.interval < 300 or args.threshold < 1:
        parser.error("interval must be >=300 and threshold >=1")
    if not re.fullmatch(r"[A-Za-z0-9.-]+:[0-9]{1,5}", args.control) or not 1 <= int(args.control.rsplit(":", 1)[1]) <= 65535:
        parser.error("control must be hostname:port")
    if args.config and (args.ip or args.port):
        parser.error("Use either --config or --ip/--port")
    if not args.config and not args.ip:
        if not sys.stdin.isatty():
            parser.error("Provide --config or --ip and --port")
        print("Public checks disclose the entered IP and TCP port to Check-Host and its probes.")
        print("This checks TCP reachability, not VPN or UDP functionality.")
        args.ip = input("Full public IPv4 address: ").strip()
        try:
            args.port = int(input("Existing TCP port: ").strip())
        except ValueError:
            parser.error("Port must be an integer")
        args.public_checks = True
    if not args.public_checks:
        parser.error("Public checks require --public-checks; target IP/port will be shared with Check-Host")
    try:
        source = json.loads(args.config.read_text(encoding="utf-8"))["targets"] if args.config else [
            {"name": args.name, "ip": args.ip, "port": args.port}]
        if not isinstance(source, list) or not 1 <= len(source) <= 20:
            raise ValueError("Provide 1-20 targets")
        targets = [validate_target(t) for t in source]
        if len({t["name"] for t in targets}) != len(targets):
            raise ValueError("Target names must be unique")
    except (OSError, ValueError, KeyError, TypeError) as error:
        parser.error(str(error))
    os.umask(0o077)
    args.output.mkdir(parents=True, exist_ok=True)
    # The advisory OS lock is released automatically after exit or a crash.
    import fcntl
    with (args.output / ".lock").open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            parser.error("Another monitor is using this output directory")
        state = {}
        try:
            saved = json.loads((args.output / "state.json").read_text(encoding="utf-8"))
            if 0 <= time.time() - saved["updated"] <= args.interval * 2:
                if isinstance(saved["targets"], dict):
                    state = saved["targets"]
        except (OSError, ValueError, KeyError, TypeError):
            pass
        while True:
            run_cycle(targets, args.control, args.output, args.threshold, state)
            if not args.watch:
                break
            time.sleep(args.interval)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\nStopped.", file=sys.stderr)
        sys.exit(130)
    except (OSError, ValueError) as error:
        print("Error: " + str(error), file=sys.stderr)
        sys.exit(2)

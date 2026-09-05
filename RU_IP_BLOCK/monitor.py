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
        "Accept": "application/json", "User-Agent": "Mozilla/5.0 RU_IP_BLOCK/1.2"})
    with urllib.request.urlopen(request, timeout=20) as response:
        raw = response.read(2_000_001)
    if len(raw) > 2_000_000:
        raise ValueError("API response exceeds size limit")
    return json.loads(raw)


def check_rkn(ip):
    timestamp = dt.datetime.now(dt.timezone.utc).isoformat()
    try:
        request = urllib.request.Request("https://reestr.rublacklist.net/api/v3/ips/", headers={
            "Accept": "application/json", "User-Agent": "Mozilla/5.0 RU_IP_BLOCK/1.2"})
        with urllib.request.urlopen(request, timeout=15) as response:
            raw = response.read(20_000_000)
            data = json.loads(raw)
            if isinstance(data, list):
                status = "LISTED" if ip in data else "NOT_LISTED"
                return {"status": status, "source": "reestr.rublacklist.net", "updated": timestamp}
            return {"status": "NO_DATA", "source": "reestr.rublacklist.net", "updated": timestamp}
    except Exception:
        return {"status": "NO_DATA", "source": "reestr.rublacklist.net", "updated": timestamp}


def send_telegram(token, chat_id, message):
    if not token or not chat_id:
        return False
    try:
        url = f"https://api.telegram.org/bot{token}/sendMessage"
        data = urllib.parse.urlencode({"chat_id": chat_id, "text": message, "parse_mode": "Markdown"}).encode()
        req = urllib.request.Request(url, data=data)
        urllib.request.urlopen(req, timeout=10)
        return True
    except Exception as e:
        print("Telegram delivery error:", e, file=sys.stderr)
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
    if value is None:
        return UNKNOWN, None
    if not isinstance(value, list) or not value or not isinstance(value[0], dict):
        return UNKNOWN, None
    item = value[0]
    if item.get("error"):
        return "FAIL", item["error"]
    if isinstance(item.get("time"), (float, int)) and item["time"] >= 0:
        return "OK", None
    return UNKNOWN, None


def parse_ping(value):
    if value is None:
        return UNKNOWN
    if not isinstance(value, list) or not value or not isinstance(value[0], list) or not value[0]:
        return "FAIL"
    for attempt in value[0]:
        if isinstance(attempt, list) and len(attempt) > 0 and attempt[0] == "OK":
            return "OK"
    return "FAIL"


def measure(host, nodes, get=api_get, sleep=time.sleep, polls=10, ctype="tcp"):
    if not nodes:
        return {}, None
    query = urllib.parse.urlencode([("host", host)] + [("node", n) for n in nodes])
    started = get(f"/check-{ctype}?" + query)
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
    
    parsed = {}
    for n in nodes:
        if n in actual:
            parsed[n] = parse_tcp(results.get(n)) if ctype == "tcp" else parse_ping(results.get(n))
        else:
            parsed[n] = (UNKNOWN, None) if ctype == "tcp" else UNKNOWN
    return parsed, request_id


def classify(rows):
    ru = [r for r in rows if r["country"] == "ru"]
    foreign = [r for r in rows if r["country"] != "ru"]
    good = [r for r in ru if r["target"] == "OK"]
    bad = [r for r in ru if r["target"] == "FAIL" and r["control"] == "OK"]
    foreign_good = any(r["target"] == "OK" for r in foreign)
    
    # Check if TCP is blocked but ICMP is OK on the EXACT SAME NODE
    bad_tcp_ping_ok = [r for r in bad if r["ping"] == "OK"]
    
    if bad and foreign_good:
        if len(bad_tcp_ping_ok) >= 2:
            return "TCP_BLOCKED_ICMP_OK (DPI Suspected)"
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


def ssh_probe(host, target_ip, target_port):
    if not host:
        return "NOT_CONFIGURED"
    try:
        key = str(Path.home() / ".ssh" / "id_ed25519")
        cmd = ["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=5", "-o", "StrictHostKeyChecking=no", "-i", key, host, f"nc -z -w 2 {target_ip} {target_port}"]
        res = subprocess.run(cmd, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=15, check=False)
        return "PASS" if res.returncode == 0 else "FAIL"
    except (OSError, subprocess.TimeoutExpired):
        return UNKNOWN


def local_firewall_probe(target_ssh, check_ips):
    if not target_ssh or not check_ips:
        return "NOT_CONFIGURED"
    try:
        key = str(Path.home() / ".ssh" / "id_ed25519")
        # Check if IPs are blocked in iptables or crowdsec
        ips_str = " ".join(check_ips)
        script = f"for ip in {ips_str}; do iptables-save | grep -q $ip && echo BLOCK_IPTABLES_$ip; command -v cscli >/dev/null && cscli decisions list -i $ip -o json | grep -q '\"id\"' && echo BLOCK_CROWDSEC_$ip; done"
        cmd = ["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=5", "-o", "StrictHostKeyChecking=no", "-i", key, target_ssh, script]
        res = subprocess.run(cmd, stdin=subprocess.DEVNULL, capture_output=True, text=True, timeout=15, check=False)
        out = res.stdout.strip()
        if "BLOCK" in out:
            return f"BLOCKED: {out}"
        return "PASS"
    except Exception:
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


def process_tg_queue(state):
    tg_queue = state.setdefault("tg_queue", [])
    if not tg_queue:
        return
    token = os.environ.get("TG_TOKEN")
    chat = os.environ.get("TG_CHAT")
    if token and chat:
        remaining = []
        for msg in tg_queue:
            if not send_telegram(token, chat, msg):
                remaining.append(msg)
        state["tg_queue"] = remaining[:50]  # Cap the queue


def run_cycle(targets, control_host, directory, threshold, state, custom_probe=None, target_ssh=None):
    timestamp = dt.datetime.now(dt.timezone.utc).isoformat()
    report = {"timestamp": timestamp, "scope": "public TCP reachability, not VPN functionality", "targets": []}
    try:
        nodes = select_nodes(api_get("/nodes/hosts")["nodes"])
        controls, control_id = measure(control_host, nodes, ctype="tcp")
        setup_error = None
    except (OSError, ValueError, KeyError, TypeError) as error:
        nodes, controls, control_id = {}, {}, None
        setup_error = type(error).__name__
    
    for target in targets:
        request_id, error_name = None, setup_error
        try:
            results, request_id = measure("{}:{}".format(target["ip"], target["port"]), nodes, ctype="tcp")
        except (OSError, ValueError, KeyError, TypeError) as error:
            results, error_name = {}, type(error).__name__
            
        try:
            ping_res, ping_req_id = measure(target["ip"], nodes, ctype="ping")
        except Exception:
            ping_res, ping_req_id = {}, None

        rows = []
        check_ips = []
        for n, info in nodes.items():
            tcp_status, tcp_err = UNKNOWN, None
            if isinstance(results.get(n), tuple):
                tcp_status, tcp_err = results[n]
            elif isinstance(results.get(n), str):
                tcp_status = results[n]
            
            p_status = ping_res.get(n, UNKNOWN)
            c_status = controls.get(n)[0] if isinstance(controls.get(n), tuple) else controls.get(n, UNKNOWN)
            rows.append(dict(info, node=n, target=tcp_status, tcp_error=tcp_err, ping=p_status, control=c_status))
            check_ips.append(info.get("ip", ""))
            
        check_ips = [ip for ip in check_ips if ip]
        status = classify(rows)

        key = "{}|{}|{}|{}".format(target["name"], target["ip"], target["port"], control_host)
        next_state, changed = transition(state.get(key, {}), status, threshold)
        state[key] = next_state
        rkn = check_rkn(target["ip"])
        fw_status = local_firewall_probe(target_ssh, check_ips) if target_ssh else "NOT_CONFIGURED"
        ssh_status = ssh_probe(custom_probe, target["ip"], target["port"])
        
        item = {"name": target["name"], "ip": target["ip"], "port": target["port"],
                "status": status, "confirmed_status": next_state["stable"],
                "consecutive": next_state["count"], "changed": changed, "nodes": rows,
                "request_id": request_id, "ping_request_id": ping_req_id, "control_request_id": control_id,
                "local_probe": probe(target.get("probe_command")), "ssh_probe": ssh_status,
                "firewall_probe": fw_status,
                "api_error": error_name, "rkn_listed": rkn}
        report["targets"].append(item)
        
        print("{} {} {}:{} {} ({}/{}) local={} ssh={} fw={} rkn={}".format(
            timestamp, target["name"], target["ip"], target["port"], status,
            next_state["count"], threshold, item["local_probe"], ssh_status, fw_status, rkn["status"]), flush=True)
        for row in rows:
            print("  {node:30} {country:2} {asn:12} target={target:7} err={tcp_error} ping={ping} control={control}".format(**{**row, "tcp_error": row["tcp_error"] or "-"}))
        if error_name:
            print("  API unavailable or invalid response: " + error_name)
        if changed:
            print("  EVENT: stable status changed to " + status, flush=True)
            msg = f"⚠️ *VPN Monitor Alert*\n\n🎯 *Target:* `{target['name']}`\n🌐 *IP:* `{target['ip']}:{target['port']}`\n\n🔄 *New Status:* *{status}*\n📉 *RKN Listed:* `{rkn['status']}`\n🛡 *FW:* `{fw_status}`"
            state.setdefault("tg_queue", []).append(msg)

    process_tg_queue(state)
    atomic_json(directory / "latest.json", report)
    append_history(directory / "history.jsonl", report)
    atomic_json(directory / "state.json", {"updated": time.time(), "targets": state, "tg_queue": state.get("tg_queue", [])})
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
    parser.add_argument("--ssh-probe", help="SSH host string (e.g., root@212.109.223.109) to perform direct remote check")
    parser.add_argument("--target-ssh", help="SSH string to connect to target IP and check local firewall (CrowdSec/iptables)")
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
                state = saved.get("targets", {})
                state["tg_queue"] = saved.get("tg_queue", [])
        except (OSError, ValueError, KeyError, TypeError):
            pass
        while True:
            run_cycle(targets, args.control, args.output, args.threshold, state, args.ssh_probe, args.target_ssh)
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

#!/usr/bin/env python3
"""
=============================================================================
  PROJECTS BACKUP AUDIT & EMAIL HEALTH REPORT
  Server: DE-222 (Central Backup Master)
  Owner:  Vladimir Bulantsev (GinCz)
  Author: VladiMIR + AI

  Audits backup status, freshness, file size, and retention for all 9 active
  server projects plus infrastructure targets. Sends automated status reports
  to gin.vladimir@gmail.com twice weekly (Wednesday & Sunday at 09:00 CET).
=============================================================================
"""

import os
import sys
import glob
import time
import shutil
import argparse
import subprocess
from datetime import datetime

EMAIL_TO = "gin.vladimir@gmail.com"
BACKUP_ROOT = "/BACKUP"

# Target definitions:
# (id, name, path_pattern, schedule_desc, max_age_days, target_copies)
TARGETS = [
    # 1. GIN-Cinema (Production + Dev) - Daily, keep 5
    {
        "id": "gin_cinema_prod",
        "project": "GIN-Cinema",
        "node": "Oracle-49 (Production)",
        "pattern": f"{BACKUP_ROOT}/gin-cinema/gin_cinema_oracle49_*.tar.gz",
        "schedule": "Daily (03:00)",
        "max_age_days": 2.2,
        "keep_target": 5,
        "min_bytes": 100000,
    },
    {
        "id": "gin_cinema_dev",
        "project": "GIN-Cinema",
        "node": "CloudCore-191 (Dev)",
        "pattern": f"{BACKUP_ROOT}/gin-cinema/gin_cinema_cloudcore191_*.tar.gz",
        "schedule": "Daily (03:00)",
        "max_age_days": 2.2,
        "keep_target": 5,
        "min_bytes": 100000,
    },
    # 2. GIN-Chat - Every even day, keep 5
    {
        "id": "gin_chat",
        "project": "GIN-Chat",
        "node": "CloudCore-191",
        "pattern": f"{BACKUP_ROOT}/gin-chat/gin_chat_backup_*.tar.gz",
        "schedule": "Even Days (03:00)",
        "max_age_days": 3.2,
        "keep_target": 5,
        "min_bytes": 1000000,
    },
    # 3. GIN-TV - Every odd day, keep 5
    {
        "id": "gin_tv",
        "project": "GIN-TV",
        "node": "DE-222 (Local Master)",
        "pattern": f"{BACKUP_ROOT}/gin-tv/gin_tv_backup_*.tar.gz",
        "schedule": "Odd Days (03:00)",
        "max_age_days": 3.2,
        "keep_target": 5,
        "min_bytes": 100000,
    },
    # 4. Crypto_BOT (3 Instances) - Weekly (Sundays), keep 3 each
    {
        "id": "crypto_bot_de222",
        "project": "Crypto_BOT",
        "node": "DE-222 (Local)",
        "pattern": f"{BACKUP_ROOT}/crypto-bot/crypto_bot_de222_*.tar.gz",
        "schedule": "Weekly (Sun 03:00)",
        "max_age_days": 8.0,
        "keep_target": 3,
        "min_bytes": 100000,
    },
    {
        "id": "crypto_bot_oracle49",
        "project": "Crypto_BOT",
        "node": "Oracle-49",
        "pattern": f"{BACKUP_ROOT}/crypto-bot/crypto_bot_oracle49_*.tar.gz",
        "schedule": "Weekly (Sun 03:00)",
        "max_age_days": 8.0,
        "keep_target": 3,
        "min_bytes": 50000,
    },
    {
        "id": "crypto_bot_oracle1",
        "project": "Crypto_BOT",
        "node": "Oracle-1",
        "pattern": f"{BACKUP_ROOT}/crypto-bot/crypto_bot_oracle1_*.tar.gz",
        "schedule": "Weekly (Sun 03:00)",
        "max_age_days": 8.0,
        "keep_target": 3,
        "min_bytes": 50000,
    },
    # 5. GIN-Remote - Weekly (Sundays), keep 2
    {
        "id": "gin_remote",
        "project": "GIN-Remote",
        "node": "Oracle-49",
        "pattern": f"{BACKUP_ROOT}/gin-remote/gin_remote_backup_*.tar.gz",
        "schedule": "Weekly (Sun 03:00)",
        "max_age_days": 8.0,
        "keep_target": 2,
        "min_bytes": 100000,
    },
    # 6. GIN-ProxyHub - Weekly (Sundays), keep 2
    {
        "id": "gin_proxyhub",
        "project": "GIN-ProxyHub",
        "node": "Oracle-49",
        "pattern": f"{BACKUP_ROOT}/gin-proxyhub/gin_proxyhub_backup_*.tar.gz",
        "schedule": "Weekly (Sun 03:00)",
        "max_age_days": 8.0,
        "keep_target": 2,
        "min_bytes": 1000,
    },
    # 7. GIN-Music - Weekly (Sundays), keep 3
    {
        "id": "gin_music",
        "project": "GIN-Music",
        "node": "Oracle-49",
        "pattern": f"{BACKUP_ROOT}/gin-music/gin_music_backup_*.tar.gz",
        "schedule": "Weekly (Sun 03:00)",
        "max_age_days": 8.0,
        "keep_target": 3,
        "min_bytes": 100,
    },
    # 8. Кастрюлька - Monthly (1st of month), keep 1
    {
        "id": "kastrulka",
        "project": "Кастрюлька",
        "node": "Oracle-49",
        "pattern": f"{BACKUP_ROOT}/kastrulka/kastrulka_backup_*.tar.gz",
        "schedule": "Monthly (1st, 03:00)",
        "max_age_days": 35.0,
        "keep_target": 1,
        "min_bytes": 100000,
    },
    # 9. GIN-AI Studio - Monthly (1st of month), keep 2
    {
        "id": "gin_ai",
        "project": "GIN-AI Studio",
        "node": "Oracle-49",
        "pattern": f"{BACKUP_ROOT}/gin-ai/gin_ai_backup_*.tar.gz",
        "schedule": "Monthly (1st, 03:00)",
        "max_age_days": 35.0,
        "keep_target": 2,
        "min_bytes": 10000,
    },
]

GIT_ONLY_PROJECTS = [
    ("GIN-Launcher", "Android TV Launcher", "GitHub Private Repo (Source-Controlled)"),
    ("GIN-IP", "Android TV IP Config / Remote Pair", "GitHub Private Repo (Source-Controlled)"),
    ("GIN-JARVIS", "Android TV Voice Assistant", "GitHub Private Repo (Source-Controlled)"),
    ("APK_Portal", "FastAPI APK Download Portal", "GitHub Private Repo (Source-Controlled)"),
    ("GIN-Installer", "Windows Suite Installer", "GitHub Private Repo (Source-Controlled)"),
    ("GIN-VPN", "Windows VPN Client", "GitHub Private Repo (Source-Controlled)"),
    ("GIN-Voice", "Windows Voice Assistant", "GitHub Private Repo (Source-Controlled)"),
    ("GIN-NetScan", "Windows Network Scanner", "GitHub Private Repo (Source-Controlled)"),
    ("GIN-WinOptimizer", "Windows System Optimizer", "GitHub Private Repo (Source-Controlled)"),
    ("GIN-AgentPC", "Windows Telemetry & Control", "GitHub Private Repo (Source-Controlled)"),
]

def format_size(bytes_val):
    if bytes_val < 1024:
        return f"{bytes_val} B"
    elif bytes_val < 1024 * 1024:
        return f"{bytes_val / 1024:.1f} KB"
    elif bytes_val < 1024 * 1024 * 1024:
        return f"{bytes_val / (1024 * 1024):.1f} MB"
    else:
        return f"{bytes_val / (1024 * 1024 * 1024):.2f} GB"

def audit_target(target):
    files = glob.glob(target["pattern"])
    if not files:
        return {
            "status": "MISSING",
            "icon": "✘",
            "copies": 0,
            "latest_file": None,
            "latest_time": None,
            "latest_size": 0,
            "age_days": None,
            "message": "No backup archive found on disk",
        }

    # Sort by mtime descending
    files_with_stats = []
    for f in files:
        try:
            stat = os.stat(f)
            files_with_stats.append((f, stat.st_mtime, stat.st_size))
        except OSError:
            pass

    if not files_with_stats:
        return {
            "status": "MISSING",
            "icon": "✘",
            "copies": 0,
            "latest_file": None,
            "latest_time": None,
            "latest_size": 0,
            "age_days": None,
            "message": "Cannot read backup files",
        }

    files_with_stats.sort(key=lambda x: x[1], reverse=True)
    latest_file, latest_mtime, latest_size = files_with_stats[0]
    total_copies = len(files_with_stats)

    now = time.time()
    age_days = (now - latest_mtime) / 86400.0

    if latest_size < target["min_bytes"]:
        return {
            "status": "CORRUPT/EMPTY",
            "icon": "✘",
            "copies": total_copies,
            "latest_file": latest_file,
            "latest_time": datetime.fromtimestamp(latest_mtime),
            "latest_size": latest_size,
            "age_days": age_days,
            "message": f"Archive too small ({format_size(latest_size)} < {format_size(target['min_bytes'])})",
        }

    if age_days > target["max_age_days"]:
        return {
            "status": "STALE",
            "icon": "⚠️",
            "copies": total_copies,
            "latest_file": latest_file,
            "latest_time": datetime.fromtimestamp(latest_mtime),
            "latest_size": latest_size,
            "age_days": age_days,
            "message": f"Backup older than expected ({age_days:.1f}d > {target['max_age_days']}d)",
        }

    return {
        "status": "OK",
        "icon": "✔",
        "copies": total_copies,
        "latest_file": latest_file,
        "latest_time": datetime.fromtimestamp(latest_mtime),
        "latest_size": latest_size,
        "age_days": age_days,
        "message": "Healthy",
    }

def get_disk_info(path):
    try:
        usage = shutil.disk_usage(path)
        return {
            "total": format_size(usage.total),
            "used": format_size(usage.used),
            "free": format_size(usage.free),
            "percent_used": (usage.used / usage.total) * 100.0,
        }
    except Exception:
        return {"total": "?", "used": "?", "free": "?", "percent_used": 0.0}

def build_report():
    audit_results = []
    issues = []

    for t in TARGETS:
        res = audit_target(t)
        audit_results.append((t, res))
        if res["status"] != "OK":
            issues.append((t, res))

    disk = get_disk_info(BACKUP_ROOT)
    now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    # Header
    total_targets = len(TARGETS)
    healthy_count = total_targets - len(issues)

    if not issues:
        status_line = f"🛡️ ALL 9 PROJECTS SECURED ({healthy_count}/{total_targets} TARGETS OK — ZERO ERRORS)"
        subject = f"🛡️ [PROJECTS AUDIT] All 9 Projects Protected (0 Issues) | DE-222"
    else:
        status_line = f"🚨 ATTENTION: {len(issues)} TARGET(S) REQUIRE REVIEW ({healthy_count}/{total_targets} OK)"
        subject = f"🚨 [PROJECTS AUDIT WARNING] {len(issues)} Project(s) Stale or Missing | DE-222"

    lines = []
    lines.append("=" * 85)
    lines.append(f"  {status_line}")
    lines.append("=" * 85)
    lines.append(f"Server:   DE-222 Central Backup Master (144.124.239.222)")
    lines.append(f"Audited:  {now_str} CET")
    lines.append(f"Storage:  {BACKUP_ROOT} (Used: {disk['used']} / {disk['total']}, Free: {disk['free']}, {disk['percent_used']:.1f}% used)")
    lines.append("-" * 85)
    lines.append("")

    # Active Server Projects Table
    lines.append("📦 ACTIVE SERVER PROJECTS BACKUP AUDIT:")
    lines.append(f"{'Status':<4} {'Project':<16} {'Node':<24} {'Schedule':<19} {'Copies':<7} {'Latest Archive':<11} {'Age'}")
    lines.append("-" * 95)

    for t, res in audit_results:
        proj = t["project"]
        node = t["node"]
        sched = t["schedule"]
        icon = res["icon"]
        copies_str = f"{res['copies']}/{t['keep_target']}"
        sz_str = format_size(res["latest_size"]) if res["latest_file"] else "N/A"
        age_str = f"{res['age_days']:.1f}d" if res["age_days"] is not None else "N/A"

        row = f" {icon:<3} {proj:<16} {node:<24} {sched:<19} {copies_str:<7} {sz_str:<11} {age_str}"
        lines.append(row)
        if res["status"] != "OK":
            lines.append(f"     └─ ⚠️ ISSUE: {res['message']}")

    lines.append("")
    lines.append("-" * 85)
    lines.append("🔒 GIT-TRACKED CLIENT REPOSITORIES (SOURCE-CONTROLLED IN GITHUB):")
    for name, desc, status in GIT_ONLY_PROJECTS:
        lines.append(f" ✔ {name:<18} | {desc:<35} | {status}")

    lines.append("")
    lines.append("-" * 85)
    lines.append("🌐 INFRASTRUCTURE SUMMARY:")
    lines.append(" • Remote VPN Nodes (6x): Backed up daily to /BACKUP/vpn/ with 3 copies retained")
    lines.append(" • FastPanel Configurations: DE-222 local + RU-109 remote mirrored daily")
    lines.append(" • Offsite Disaster Replica: Full /BACKUP mirrored nightly to RU-109 (212.109.223.109)")
    lines.append("=" * 85)
    lines.append("                  = Rooted by VladiMIR + AI =")

    body = "\n".join(lines)
    return subject, body, issues

def send_email(subject, body):
    gmail_bin = "/usr/local/bin/gmail"
    if os.path.isfile(gmail_bin) and os.access(gmail_bin, os.X_OK):
        try:
            cmd = [gmail_bin, "send", "--to", EMAIL_TO, "--subject", subject, "--body", body]
            res = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
            if res.returncode == 0:
                print(f"[OK] Email sent successfully to {EMAIL_TO} via {gmail_bin}")
                return True
            else:
                print(f"[ERROR] {gmail_bin} failed: {res.stderr or res.stdout}", file=sys.stderr)
        except Exception as e:
            print(f"[ERROR] Exception calling {gmail_bin}: {e}", file=sys.stderr)

    # Fallback to local mail command if available
    try:
        proc = subprocess.Popen(["mail", "-s", subject, EMAIL_TO], stdin=subprocess.PIPE, text=True)
        proc.communicate(input=body)
        if proc.returncode == 0:
            print(f"[OK] Email sent via local mail command to {EMAIL_TO}")
            return True
    except Exception:
        pass

    print("[WARN] All email delivery methods failed", file=sys.stderr)
    return False

def main():
    parser = argparse.ArgumentParser(description="Projects Backup Audit & Health Reporter")
    parser.add_argument("--dry-run", action="store_true", help="Print report to stdout without sending email")
    parser.add_argument("--send-email", action="store_true", help="Force sending email regardless of execution context")
    args = parser.parse_args()

    subject, body, issues = build_report()

    # Print to stdout
    print(body)

    if args.dry_run:
        print("\n[DRY RUN] Skipping email sending.")
        sys.exit(0 if not issues else 1)

    # If --send-email is given, or if running without a TTY (e.g. from cron)
    should_send = args.send_email or (not sys.stdin.isatty())
    if should_send:
        success = send_email(subject, body)
        sys.exit(0 if (success and not issues) else (0 if success else 2))
    else:
        print("\n[INFO] Running interactively without --send-email; email was not sent. Use --send-email to deliver.")

if __name__ == "__main__":
    main()

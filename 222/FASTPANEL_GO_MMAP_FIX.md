# FastPanel File Manager — Go runtime mmap crash fix

> **Server:** 152.53.182.222 (EU-NetCup, Ubuntu 24 / FASTPANEL)  
> **Date:** 2026-05-31  
> **Affected user/site:** `wowflow` (`wowflow.cz`)  
> **Service:** `filemanagersystemd@wowflow.service`

---

## Symptom

File Manager in FastPanel refused to open for user `wowflow`.
The service crashed immediately at start with:

```
fatal error: failed to reserve page summary memory

runtime stack:
runtime.throw({0xbe155d?, 0x7755f2ca3008?})
        /usr/local/go/src/runtime/panic.go:1101 +0x48
runtime.(*pageAlloc).sysInit(0x11b5f88, 0xd8?)
        /usr/local/go/src/runtime/mpagealloc_64bit.go:81 +0x11c
runtime.(*pageAlloc).init(0x11b5f88, ...)
runtime.(*mheap).init(0x11b5f80)
runtime.mallocinit()
runtime.schedinit()
runtime.rt0_go()
        /usr/local/go/src/runtime/asm_amd64.s:349
```

Process exited with `status=2` before reaching `main()`.

---

## Root Cause

**`/etc/security/limits.conf` contained:**
```
@wowflow hard nproc 50
@wowflow hard as   300000
```

The `hard as` parameter limits **virtual address space** in kilobytes (here: ~293 MB).

The Go runtime on 64-bit Linux **unconditionally reserves a huge contiguous virtual
address space** (~300+ GB) via `mmap(MAP_ANONYMOUS|MAP_NORESERVE)` during
initialisation (`pageAlloc.sysInit` in `mpagealloc_64bit.go`).  
This reservation is **virtual only** — Go does not actually allocate physical RAM —
but the kernel enforces the `RLIMIT_AS` (address-space) limit against `mmap` calls,
causing the reservation to fail and Go to panic before `main()` is reached.

**Why increasing `as` to 600000 also failed:**  
Go needs several hundred gigabytes of virtual space for its page allocator bitmap.
No reasonable KB value for `hard as` is compatible with Go processes.

---

## Fix Applied

```bash
# Remove only the hard as line — nproc 50 kept as a reasonable process limit
sed -i '/@wowflow hard as/d' /etc/security/limits.conf

# Reload and start service
systemctl daemon-reload
systemctl reset-failed filemanagersystemd@wowflow.service
systemctl start filemanagersystemd@wowflow.service
systemctl status filemanagersystemd@wowflow.service --no-pager -n 5
```

**Result after fix:**
```
● filemanagersystemd@wowflow.service
   Active: active (running) since Sun 2026-05-31 01:19:34 CEST
   Main PID: 2309475 (/bin/su wowflow -s /bin/bash ...)
```

**File Manager opened instantly without errors. ✅**

---

## Final state of /etc/security/limits.conf (wowflow section)

```
@wowflow hard nproc 50
# hard as — REMOVED. Go runtime requires unrestricted virtual address space.
# See: 222/FASTPANEL_GO_MMAP_FIX.md
```

---

## Important Notes

| Limit | Safe for Go? | Notes |
|---|---|---|
| `hard nproc 50` | ✅ Yes | Limits process count, does not affect mmap |
| `hard as <any value>` | ❌ No | Go runtime panics at startup — never set for Go apps |
| `hard nofile` | ✅ Yes | File descriptor limit, safe |
| `hard memlock` | ✅ Yes | Physical locked memory, safe |

> **Rule:** Never set `hard as` (RLIMIT_AS) for any user running Go binaries.
> FastPanel's filemanager is a Go binary — this applies to ALL FastPanel users.

---

## Scope Check (2026-05-31)

- **Server 222 (152.53.182.222):** No other `hard as` entries ✅  
- **Server 109 (212.109.223.109):** No `hard as` entries, no filemanager services ✅  

---

> _= Rooted by VladiMIR + AI | v.2026.05.31 | github.com/GinCz =_

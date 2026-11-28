# Bare-Metal Disk Wipe Utility (`wipe_disk.sh`)

> Repository: [GinCz/Linux_Server_Public](https://github.com/GinCz/Linux_Server_Public)  
> Author: [Vladimir Bulantsev (@GinCz)](https://github.com/GinCz)  
> License: MIT

> ⚠️ **CRITICAL WARNING:** This utility executes low-level block wiping on `/dev/sda`. It permanently and irreversibly destroys all partition tables (GPT/MBR), filesystems, and data. There is NO undo. Use strictly in rescue environments (e.g. GRML Live Linux) before reinstallation or server decommissioning.

---

## ⚡ Overview

When provisioning bare-metal dedicated servers or transitioning between operating systems, residual partition signatures, LVM metadata, and software RAID superblocks often cause installer crashes.

`wipe_disk.sh` provides a deterministic clean-slate reset:
1. Unmounts all active mounts on `/dev/sda*`.
2. Wipes filesystem/partition signatures using `wipefs -a -f`.
3. Overwrites partition tables (MBR, GPT, backup GPT) with zero blocks (`dd`).
4. Re-reads partition tables via `partprobe` to confirm clear state.

---

## 🚀 Execution (Rescue / Live OS Only)

Run directly in a rescue or live environment:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/WipeDisk/wipe_disk.sh)
```

Interactive safety confirmation requires typing `YES` before any destruction proceeds.

---

## 📋 Version History

<details>
<summary><b>Click to expand changelog</b></summary>

### v2026-07-29
* Added multi-step visual warning banner and interactive safety verification prompt.
* Added `wipefs -a -f` and kernel `partprobe` synchronization.
* Zeroed first and last 200MB to wipe both primary and backup GPT structures.

</details>

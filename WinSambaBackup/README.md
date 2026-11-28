# Bare-Metal Server Backup over SMB / Samba (`WinSambaBackup`)

> Repository: [GinCz/Linux_Server_Public](https://github.com/GinCz/Linux_Server_Public)  
> Author: [Vladimir Bulantsev (@GinCz)](https://github.com/GinCz)  
> Directory: `WinSambaBackup/`

Enterprise backup utility designed to stream disk images, partition tables, and directory archives directly to remote Windows SMB/Samba network shares.

---

## ⚡ Key Capabilities

* **Direct Network Streaming:** Streams compressed `tar.gz` or raw partition dumps directly to SMB network storage (`cifs`), preventing local disk space exhaustion.
* **Auto-Mount & Unmount:** Mounts designated SMB shares with authentication, executes verified backups, and cleanly unmounts upon completion.
* **Integrity Validation:** Computes SHA-256 hashes of generated archives for corruption detection.

---

## 🚀 Execution

```bash
sudo bash backup_to_smb.sh
```

---

## 🏷️ Keywords & Topics
`#samba-backup` `#smb-storage` `#bare-metal-backup` `#linux-to-windows` `#disaster-recovery`

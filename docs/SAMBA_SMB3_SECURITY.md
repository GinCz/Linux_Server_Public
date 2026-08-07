# Secure SMB3 Samba Baseline

## Scope

This document defines the hardened Samba baseline used on the Ubuntu VPN and file servers. It preserves existing users, passwords, shares, filesystem permissions, and share paths while removing legacy NetBIOS exposure.

## Required global settings

```ini
[global]
    server min protocol = SMB3_11
    server max protocol = SMB3_11
    smb encrypt = required
    server signing = mandatory
    disable netbios = yes
    smb ports = 445
    map to guest = Never
```

Samba may display `SMB3_11` as `SMB3` in shortened `testparm -s` output. Verify the effective encryption setting with:

```bash
testparm -sv | grep -Ei 'server min protocol|server max protocol|server smb encrypt|server signing|disable netbios|smb ports'
```

The expected result includes `server smb encrypt = required`, `server signing = required`, `disable netbios = Yes`, and `smb ports = 445`.

## Legacy services and firewall

Stop and mask `nmbd`. Do not expose TCP 139 or UDP 137/138. Keep only TCP 445 for SMB, and restrict TCP 445 to trusted VPN or administrative source networks whenever possible.

## Preservation requirements

Before changing Samba, back up `/etc/samba`, `/var/lib/samba`, the active firewall configuration, `smb.conf`, and the Samba passdb. Never reset Samba passwords or change share paths during a security migration.

## Windows compatibility

Windows 10 and Windows 11 can use the existing UNC paths and credentials. The client does not need a new share name when only the server protocol and security settings are changed.

## Validation

```bash
testparm -s
systemctl is-active smbd
systemctl is-inactive nmbd
ss -lntup | grep -E ':(139|445)\\b'
pdbedit -L
```

Only TCP 445 should be listening. Existing users and shares must be listed after the change.

= Rooted by VladiMIR + AI | v.2026.08.08 | github.com/GinCz =
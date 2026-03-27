# Ansible Playbooks for Semaphore

**Version:** v2026-03-27
**Semaphore UI:** https://sem.gincz.com
*= Rooted by VladiMIR | AI =*

## Playbooks

| File | Description | Hosts |
|------|-------------|-------|
| `ping.yml` | Test connectivity + uptime | all |
| `server_info.yml` | OS, RAM, CPU, disk info | all |
| `docker_status.yml` | Docker containers status | servers_main (222) |
| `update_servers.yml` | apt update (NO upgrade) | all |

## Inventory groups

```ini
[servers_main]  -> 222 (xxx.xxx.xxx.222) + 109 (xxx.xxx.xxx.109)
[servers_vpn]   -> TATRA-9 (xxx.xxx.xxx.9)
[all]           -> everything
```

## In Semaphore — Task Template settings

- **Repository:** Linux-Server-Public
- **Playbook path:** `ansible/ping.yml`
- **Inventory:** All-Servers
- **Variable Group:** production
- **SSH Key:** root-password (for main servers) / vpn-ssh-key (for VPN)

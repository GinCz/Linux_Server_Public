# 🛡️ IPGuard — Repository Migration Notice

> **Notice:** The **IPGuard** distributed security system has officially moved to the dedicated directory:
> 
> 👉 **[`/IPGuard/`](../IPGuard/README.md)**

---

### 🔗 Current Project Resources

* 📖 **Documentation & Full Guide:** [`/IPGuard/README.md`](../IPGuard/README.md)
* 🛡️ **Master Collector (Phase 2):** [`/IPGuard/collect-from-vpn.sh`](../IPGuard/collect-from-vpn.sh)
* 🚀 **Global Deployer (Phase 3):** [`/IPGuard/deploy-blacklist.sh`](../IPGuard/deploy-blacklist.sh)
* 📥 **Live Blacklist (Plain text):** `https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/IPGuard/blacklist.txt`
* 📊 **Live Database (CSV):** `https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/IPGuard/blacklist-full.csv`

---

### 🔄 Backward Compatibility

All previous links, bookmarks, and automated scripts pointing to `/blacklist/` continue to work:
* `blacklist/blacklist.txt` and `blacklist/blacklist-full.csv` are automatically synced and updated in real time.
* Wrapper scripts in this directory transparently forward to `/IPGuard/`.

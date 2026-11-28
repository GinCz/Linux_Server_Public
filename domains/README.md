# Multi-Domain Health & SSL Certificate Monitor (`domains`)

> Repository: [GinCz/Linux_Server_Public](https://github.com/GinCz/Linux_Server_Public)  
> Author: [Vladimir Bulantsev (@GinCz)](https://github.com/GinCz)  
> Directory: `domains/`

High-speed parallel HTTP response code, DNS routing, and TLS/SSL certificate expiration validator for web hosting clusters.

---

## ⚡ Overview & Features

* **Parallel Domain Verification:** Probes hundreds of hosted virtual domains concurrently via `curl`.
* **SSL Expiration Sentinel:** Calculates days remaining until Let's Encrypt or custom SSL certificate expiry, warning before renewal failures.
* **HTTP Status Code Mapping:** Validates 200 OK, 301/302 redirects, and detects broken 404/500/502 Bad Gateway responses.

---

## 🚀 Execution

```bash
bash domain_check.sh
```

---

## 🏷️ Keywords & Topics
`#domain-monitor` `#ssl-checker` `#tls-monitoring` `#http-status` `#webmaster-tools` `#uptime-monitor`

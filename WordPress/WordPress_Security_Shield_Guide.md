# đź›ˇď¸Ź WordPress Incident Forensics, Audit & Defense Framework Shield_VladiMIR+AI

> **Comprehensive guide on web application incident investigation, exploit vectors, rapid forensic diagnostics, and multi-tier WordPress hardening.**
> 
> *Repository:* [Linux_Server_Public â†—](https://github.com/GinCz/Linux_Server_Public) | *Author:* [Vladimir Bulantsev (GinCz) â†—](https://github.com/GinCz) & AI Assistant | *Incident Reference:* 2026.09.06

---

## đź“Ś 1. Anatomy of WordPress Exploits & Attack Vectors

Automated botnets targeting WordPress installations leverage coordinated exploit chains:

### Vector 1: User Enumeration
- **Mechanism:** Automated bots query /?author=1, /?author=2 or poll the REST API endpoint /wp-json/wp/v2/users.
- **Mitigation:** Rewrite author queries via .htaccess and restrict REST API user schema exposure.

### Vector 2: XML-RPC Amplification & Multi-Call Brute Force
- **Mechanism:** Attackers invoke xmlrpc.php using the system.multicall method, allowing hundreds of credential pairs per single HTTP request while bypassing /wp-login.php rate limits.
- **Mitigation:** Block all direct HTTP requests to xmlrpc.php at web server level (.htaccess / Nginx / Cloudflare WAF).

### Vector 3: Vulnerable Legacy Plugins & Privilege Escalation
- **Mechanism:** Unpatched plugins with **Unauthenticated Privilege Escalation** or **Arbitrary File Upload** bugs allow attackers to register administrative accounts via AJAX handlers.
- **Mitigation:** Replace monolithic plugins with ultra-light native micro-plugins; enforce strict file permission masks.

### Vector 4: Persistence, WebShells & Core Alteration
- **Mechanism:** Attackers upload PHP shells into /wp-content/uploads/ and modify core files (e.g. wp-admin/includes/update-core.php) to re-establish backdoor persistence.
- **Mitigation:** Enforce .htaccess-uploads to permanently prohibit execution of .php, .phtml, .cgi, .pl, and .sh within uploads directories.

---

## âšˇ 2. Ten-Second Diagnostic Triage (WP-CLI Commands)

Execute these commands in the terminal to inspect server health:

### 1. Enumerate All Administrators:
`ash
wp user list --role=administrator --allow-root --path=/var/www/USER/data/www/DOMAIN --fields=ID,user_login,user_email,user_registered
`
> **Red Flag:** Accounts with disposable email domains (@wp2shell.invalid, @service.localhost), pseudorandom strings (wp2_*, sys_*, oot_*), or unrecognized creation timestamps.

### 2. Verify WordPress Core Integrity:
`ash
wp core verify-checksums --allow-root --path=/var/www/USER/data/www/DOMAIN
`
> **Red Flag:** Warnings such as File doesn't verify against checksum or File should not exist.

### 3. Detect PHP Scripts in Media Uploads:
`ash
find /var/www/USER/data/www/DOMAIN/wp-content/uploads -type f \( -name "*.php*" -o -name "*.phtml" -o -name "*.phar" \) -ls
`
> **Red Flag:** Any executable file discovered inside /uploads/.

---

## đź›ˇď¸Ź 3. Multi-Layer Defense Deployment

1. **Root Protection:** Deploy [.htaccess-root](./htaccess_Shield/.htaccess-root) to website document root.
2. **Uploads Hardening:** Deploy [.htaccess-uploads](./htaccess_Shield/.htaccess-uploads) to /wp-content/uploads/.htaccess.
3. **Core Replacement:** Replace compromised core files using official pristine archives:
   `ash
   wp core download --force --skip-content --allow-root --path=/var/www/USER/data/www/DOMAIN
   `
4. **Credential Rotation:** Rotate MySQL database credentials in wp-config.php and regenerate security authentication salts via [WordPress Salt API â†—](https://api.wordpress.org/secret-key/1.1/salt/).

# Cloudflare WAF Security Rules

Apply these custom rules in Cloudflare (Security -> WAF -> Custom rules) for each domain using the proxy (orange cloud).

## 1. Block XMLRPC
- Action: Block
- Expression:
(http.request.uri.path eq "/xmlrpc.php") or (http.request.uri.path eq "//xmlrpc.php")

## 2. Challenge WP-Admin & Login
- Action: Managed Challenge
- Expression:
(http.request.uri.path eq "/wp-login.php" or http.request.uri.path eq "//wp-login.php")
or (
  (starts_with(http.request.uri.path, "/wp-admin/") or starts_with(http.request.uri.path, "//wp-admin/"))
  and not (http.request.uri.path eq "/wp-admin/admin-ajax.php" or http.request.uri.path eq "//wp-admin/admin-ajax.php")
)

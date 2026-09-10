# WP Test Email Micro (VladiMIR+AI)

**Version:** 2026.09.10  
**License:** GPL-2.0-or-later

## Purpose

A small administrator-only tool at **Tools → Test Email**. It sends one explicit test message through the WordPress mail transport and reports whether `wp_mail()` accepted it.

## What it does not do

- Does not create or query database tables.
- Does not intercept or retain any outgoing email.
- Does not run on public requests.
- Does not claim successful inbox delivery; it confirms only that WordPress handed the message to its configured mail transport.

## Security and performance

The form requires the `manage_options` capability, a WordPress nonce, validated recipient email, and escaped output. Its only hook adds the Tools page in the administrator area.

## Replaces

`wp-test-email` v1.1.9 on `detailing-alex.eu`. The replaced plugin creates a `test_email_logs` table and globally records outgoing email, neither of which is needed for an intentional delivery check.

## Installation

1. Install `wp-test-email-micro-(VladiMIR+AI).zip` in **Plugins → Add New → Upload Plugin**.
2. Activate **WP Test Email Micro**.
3. Open **Tools → Test Email**, enter a controlled recipient address, and send one test.
4. After verification, deactivate and remove the old `wp-test-email` plugin.

For server deployment, use WP-CLI as the website owner and verify both the plugin status and a real received message.

# WP Allow Safe HTML in Categories (VladiMIR+AI)

**Version:** 2026.09.11
**License:** GPL-2.0-or-later

## Purpose

Allows safe WordPress post-style HTML in category, tag, and custom-taxonomy descriptions. It supports useful markup such as paragraphs, headings, links, lists, emphasis, and images while continuing to remove scripts, event attributes, and other unsafe content.

## Security and performance

The plugin replaces the restrictive term-description filters with `wp_kses()` and WordPress's built-in post allow-list. It creates no database tables, background jobs, settings page, remote request, or public JavaScript.

## Installation

1. Copy the `wp-allow-html-cats` directory to `wp-content/plugins/`.
2. Activate **WP Allow Safe HTML in Categories**.
3. Edit a category description and save it.

Do not use the older two-line approach that removes KSES filtering completely: that permits stored XSS for users who can edit taxonomy descriptions.

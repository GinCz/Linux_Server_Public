# Server 222 Notes

## v2026-03-17
- Long heredoc paste over SSH may hang or break on this server.
- For large script updates, prefer python3 stdin write instead of cat <<EOF.
- amnezia_stat.sh works, but formatting may differ from VPN nodes.
- Use short commands and separate commit/push steps.

- Prefer normal single-block paste first.
- Use python3 stdin write only as a fallback for long files when SSH paste or heredoc hangs.

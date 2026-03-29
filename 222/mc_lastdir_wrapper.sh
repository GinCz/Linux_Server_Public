#!/bin/bash
clear
# =============================================================================
# mc_lastdir_wrapper.sh — Midnight Commander with last-dir memory
# =============================================================================
# Version  : v2026-03-30
# Author   : Ing. VladiMIR Bulantsev
# GitHub   : https://github.com/GinCz/Linux_Server_Public
# -----------------------------------------------------------------------------
# WHAT IT DOES:
#   - Launches mc with -P flag so mc writes last active dir on exit
#   - On next launch: both panels restore their last visited directory
#   - Left panel  → last dir from LEFT panel (or $HOME if first run)
#   - Right panel → last dir from RIGHT panel (or /root if first run)
#
# HOW TO INSTALL (run once on server):
#   cp /root/Linux_Server_Public/222/mc_lastdir_wrapper.sh /root/.mc_lastdir_wrapper.sh
#   chmod +x /root/.mc_lastdir_wrapper.sh
#   source /root/.bashrc
#
# USAGE: just type  m  or  mc  (both are aliased to this wrapper)
# =============================================================================
# = Rooted by VladiMIR | AI =
# =============================================================================

LASTDIR_FILE="${HOME}/.cache/mc/lastdir"
LEFT_DIR="${HOME}"
RIGHT_DIR="/root"

# Read last active directory saved by mc -P
if [ -f "${LASTDIR_FILE}" ]; then
    LASTDIR=$(cat "${LASTDIR_FILE}" 2>/dev/null)
    if [ -d "${LASTDIR}" ]; then
        LEFT_DIR="${LASTDIR}"
    fi
fi

# Launch mc:
#   -P <file>  : write last dir to file on exit
#   left panel : LEFT_DIR
#   right panel: RIGHT_DIR (kept separate — mc remembers both internally)
mc -P "${LASTDIR_FILE}" "${LEFT_DIR}" "${RIGHT_DIR}"

# After mc exits — cd into the last active directory in the shell
if [ -f "${LASTDIR_FILE}" ]; then
    NEWDIR=$(cat "${LASTDIR_FILE}" 2>/dev/null)
    if [ -d "${NEWDIR}" ]; then
        cd "${NEWDIR}" 2>/dev/null
    fi
fi

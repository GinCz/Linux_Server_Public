#!/usr/bin/env bash
# Script:  load.sh
# Version: v2026-03-17
# Purpose: Pull latest changes from GitHub repository.
# Usage:   /opt/server_tools/scripts/load.sh
# Alias:   load

cd /opt/server_tools && git pull --rebase && echo "Updated OK"

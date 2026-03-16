#!/usr/bin/env bash
cd /root/scripts
echo "🔄 Synchronizing security lists with GitHub..."
git pull origin main
echo "✅ Synchronization complete!"

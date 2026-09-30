#!/bin/bash
# Builds and installs (or updates) the Desktop Shell for the current user:
#   ~/Library/Application Support/Desktop Shell/*.app      the 4 background services
#   ~/Library/LaunchAgents/local.dhairyabhatia.desktop.*   start them at login, restart on crash
#
#   ./install.sh               build + install / update
#   ./install.sh --uninstall   remove everything (gives back the Dock and Finder's icons)
set -euo pipefail
cd "$(dirname "$0")"

if [ "${1:-}" = "--uninstall" ]; then
    scripts/shell.sh uninstall
    exit 0
fi
./build.sh
scripts/shell.sh install build
echo "Control the services with:  ./desktopctl status | stop | start | restart | disable | enable  <service|all>"

#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG="$HERE/package"
PLUGIN_ID="org.kde.plasma.wavebar"

if ! command -v kpackagetool6 >/dev/null 2>&1; then
    echo "kpackagetool6 not found — install KDE Plasma 6 development tools." >&2
    exit 1
fi

if ! command -v parec >/dev/null 2>&1; then
    echo "Warning: 'parec' not found. Install pulseaudio-utils (or pipewire-pulse)." >&2
fi

if ! python3 -c 'import numpy' 2>/dev/null; then
    echo "Warning: python3 numpy not found. On Fedora: sudo dnf install python3-numpy" >&2
fi

chmod +x "$PKG/contents/code/spectrum-daemon.py"

ACTION="install"
if kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep -qx "$PLUGIN_ID"; then
    ACTION="upgrade"
fi

echo ">>> ${ACTION}ing $PLUGIN_ID"
if [ "$ACTION" = "upgrade" ]; then
    kpackagetool6 -t Plasma/Applet -u "$PKG"
else
    kpackagetool6 -t Plasma/Applet -i "$PKG"
fi

# Install the widget icon into the user's hicolor theme so KIconLoader
# can resolve "wavebar" by name (it doesn't search the package's
# own contents/icons/ folder).
ICON_SRC="$PKG/contents/icons/wavebar.svg"
ICON_DEST_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"
if [ -f "$ICON_SRC" ]; then
    mkdir -p "$ICON_DEST_DIR"
    cp "$ICON_SRC" "$ICON_DEST_DIR/wavebar.svg"
    gtk-update-icon-cache "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true
    kbuildsycoca6 >/dev/null 2>&1 || true
fi

echo
echo "Restart plasmashell to pick up changes:"
echo "    systemctl --user restart plasma-plasmashell.service"
echo "or:"
echo "    kquitapp6 plasmashell && kstart plasmashell &"
echo
echo "Then right-click the panel → 'Add or Manage Widgets…' → search 'Wavebar'."

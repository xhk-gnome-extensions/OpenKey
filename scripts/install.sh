#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/build}"
PREFIX="${PREFIX:-/usr}"
BUILD_TYPE="${BUILD_TYPE:-RelWithDebInfo}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix)
      PREFIX="${2:?missing value for --prefix}"
      shift 2
      ;;
    --build-dir)
      BUILD_DIR="${2:?missing value for --build-dir}"
      shift 2
      ;;
    --build-type)
      BUILD_TYPE="${2:?missing value for --build-type}"
      shift 2
      ;;
    -h|--help)
      cat <<EOF
Usage: $(basename "$0") [--prefix PREFIX] [--build-dir DIR] [--build-type TYPE]

Environment:
  PREFIX=/usr
  BUILD_DIR=./build
  BUILD_TYPE=RelWithDebInfo
EOF
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

echo "[openkey] Configuring: buildDir=$BUILD_DIR prefix=$PREFIX buildType=$BUILD_TYPE"

cmake -S "$ROOT_DIR" -B "$BUILD_DIR" \
  -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
  -DCMAKE_INSTALL_PREFIX="$PREFIX"

echo "[openkey] Building"
cmake --build "$BUILD_DIR" -j

echo "[openkey] Installing (sudo)"
sudo cmake --install "$BUILD_DIR"

if [[ "$(uname -s)" == "Linux" ]]; then
  if [[ ! -e /dev/uinput ]]; then
    echo "[openkey] /dev/uinput missing; trying: sudo modprobe uinput (best-effort)"
    sudo modprobe uinput >/dev/null 2>&1 || true
  fi

  if [[ -e /dev/uinput ]]; then
    if ! getent group uinput >/dev/null 2>&1; then
      echo "[openkey] Creating system group: uinput (best-effort)"
      sudo groupadd --system uinput >/dev/null 2>&1 || true
    fi

    if [[ -d /etc/udev/rules.d ]] && command -v udevadm >/dev/null 2>&1; then
      echo "[openkey] Installing udev rule for /dev/uinput (best-effort)"
      sudo tee /etc/udev/rules.d/99-openkey-uinput.rules >/dev/null <<'EOF' || true
# OpenKey: allow members of group "uinput" to access /dev/uinput.
KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", MODE="0660", GROUP="uinput"
EOF
      sudo udevadm control --reload-rules >/dev/null 2>&1 || true
      sudo udevadm trigger --name-match=uinput >/dev/null 2>&1 || true
    fi
  else
    echo "[openkey] Warning: /dev/uinput not found; uinput backspace injection won't work"
  fi
fi

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  echo "[openkey] Updating icon cache (optional)"
  sudo gtk-update-icon-cache -f -t "$PREFIX/share/icons/hicolor" >/dev/null 2>&1 || true
fi

echo "[openkey] Restarting fcitx5"
fcitx5 -rd >/dev/null 2>&1 || true

cat <<EOF
[openkey] Done.

Next:
  - Open \`fcitx5-configtool\` -> Add input method -> "OpenKey"
  - If you don't see it yet, try log out/in and run: \`fcitx5 -rd\`
EOF

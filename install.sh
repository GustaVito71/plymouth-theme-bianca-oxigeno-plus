#!/bin/bash
# Instalador del tema Plymouth Bianca Oxigeno Plus
set -euo pipefail

THEME_NAME="bianca-oxigeno-plus"
THEME_DIR="/usr/share/plymouth/themes/$THEME_NAME"
CONF="/etc/plymouth/plymouthd.conf"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$PATH:/usr/sbin:/sbin"

# Solo los archivos que forman el tema (README, LICENSE, assets, .git, etc.
# no se copian: Plymouth incluye la carpeta del tema en el initramfs)
FILES=(
  "$THEME_NAME.plymouth" "$THEME_NAME.script"
  animation.png background.png box.png bullet.png entry.png lock.png
  logo.png progress_bar.png progress_box.png suspend.png
)

if [ "$EUID" -ne 0 ]; then
  echo "Ejecutá este script con sudo: sudo ./install.sh"
  exit 1
fi

if [ "$SRC_DIR" = "$THEME_DIR" ]; then
  echo "Ejecutá el instalador desde una copia del repositorio fuera de $THEME_DIR"
  exit 1
fi

for f in "${FILES[@]}"; do
  [ -f "$SRC_DIR/$f" ] || { echo "Falta el archivo $f"; exit 1; }
done

echo "Instalando el tema Plymouth Bianca Oxigeno Plus..."
install -d -m 755 "$THEME_DIR"
for f in "${FILES[@]}"; do
  install -m 644 "$SRC_DIR/$f" "$THEME_DIR/$f"
done

# Seleccionar el tema y regenerar el initramfs
if command -v plymouth-set-default-theme >/dev/null 2>&1; then
  plymouth-set-default-theme -R "$THEME_NAME"
else
  # Theme= en plymouthd.conf tiene prioridad sobre el tema por defecto
  mkdir -p "$(dirname "$CONF")"
  if [ -f "$CONF" ] && grep -q '^Theme=' "$CONF"; then
    sed -i "s/^Theme=.*/Theme=$THEME_NAME/" "$CONF"
  elif [ -f "$CONF" ] && grep -q '^\[Daemon\]' "$CONF"; then
    sed -i "/^\[Daemon\]/a Theme=$THEME_NAME" "$CONF"
  else
    printf '[Daemon]\nTheme=%s\n' "$THEME_NAME" >> "$CONF"
  fi

  if command -v update-initramfs >/dev/null 2>&1; then
    update-initramfs -u
  elif command -v dracut >/dev/null 2>&1; then
    dracut -f
  else
    echo "Aviso: regenerá el initramfs manualmente para ver el tema al arrancar."
  fi
fi

echo "¡Tema instalado! Reiniciá para ver los cambios."

#!/bin/bash
# EN: Syncs the Obsidian vault with GitHub.
#     Pulls remote changes and pushes local changes made by Hermes.
#     Location in the container: ~/sync-vault.sh (chmod +x ~/sync-vault.sh)
#     Run automatically every 5 minutes by the systemd timer vault-sync.timer.
#
# ES: Sincroniza el vault de Obsidian con GitHub.
#     Descarga los cambios remotos y sube los cambios locales hechos por Hermes.
#     Ubicación en el contenedor: ~/sync-vault.sh (chmod +x ~/sync-vault.sh)
#     Lo ejecuta automáticamente el timer systemd vault-sync.timer cada 5 minutos.

cd ~/vault || exit 1
git pull --rebase --autostash -q
git add -A
if ! git diff --cached --quiet; then
  git commit -q -m "Hermes: $(date '+%Y-%m-%d %H:%M')"
  git push -q
fi

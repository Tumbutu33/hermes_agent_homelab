# 9. Mantenimiento

🌐 [English](../en/09-maintenance.md) · **Español**

[← Anterior: Decisiones de diseño](08-decisiones-de-diseno.md) · [Índice](../../README.es.md)

Tareas habituales para mantener el sistema actualizado, revisar su estado y recuperarse de errores. Todos los comandos se ejecutan en el contenedor como `hermes`, salvo que se indique otra cosa.

## Revisar el estado

| Para saber… | Comando |
| --- | --- |
| Estado general de Hermes | `curl http://127.0.0.1:9119/api/status` (buscar `"overall":"ok"`) |
| Si el gateway responde | `curl http://127.0.0.1:8642/health` |
| Si Workspace está activo | `systemctl --user status hermes-workspace` |
| Si el timer del vault está activo | `systemctl --user list-timers` |
| Últimas sincronizaciones | `journalctl --user -u vault-sync.service -n 20` |
| Cambios pendientes en el vault | `cd ~/vault && git status` |
| Últimos commits del vault | `cd ~/vault && git log --oneline -5` |
| Dispositivos en Tailscale | `tailscale status` |
| Dirección publicada | `tailscale serve status` |

## Actualizar Hermes

```bash
hermes update
```

Después, reinicia el panel y el gateway para que usen la versión nueva:

```bash
systemctl --user restart hermes-dashboard
```

```bash
systemctl --user list-units | grep -i hermes
```

```bash
systemctl --user restart <nombre-del-servicio-del-gateway>
```

O reinicia el contenedor desde Proxmox. Comprueba con `curl http://127.0.0.1:9119/api/status`.

## Actualizar Hermes Workspace

Es preferible actualizar desde la terminal en lugar de usar el aviso de la interfaz: así se ven los errores.

```bash
cd ~/hermes-workspace
```

```bash
git pull
```

```bash
pnpm install
```

```bash
pnpm build
```

```bash
systemctl --user restart hermes-workspace
```

Si `git pull` se queja de cambios locales en `.env`, no ocurre nada: `.env` no forma parte del repositorio de Workspace. Si se queja de otros archivos, revisa con `git status` antes de continuar.

Las actualizaciones no afectan al vault, a la sincronización con GitHub ni a la memoria de Hermes.

## Copias de seguridad

| Qué | Dónde está | Respaldo |
| --- | --- | --- |
| Vault de Obsidian | PC, GitHub y contenedor | Ya respaldado en GitHub, con historial |
| Memoria, skills y configuración de Hermes | `~/.hermes` en el contenedor | Copia del contenedor en Proxmox |
| Configuración de Workspace | `~/hermes-workspace/.env` | Copia del contenedor en Proxmox |

Antes de actualizaciones importantes, haz una copia del contenedor: Proxmox → contenedor → **Backup → Backup now**. Si el almacenamiento lo admite (por ejemplo, ZFS o LVM-thin), una **Snapshot** es todavía más rápida de crear y de restaurar.

## Deshacer un cambio de Hermes en el vault

Cada cambio queda en el historial, así que nada se pierde.

```bash
cd ~/vault
```

```bash
git log --oneline -10
```

Copia el código del commit a deshacer (por ejemplo, `a1b2c3d`):

```bash
git revert a1b2c3d
```

```bash
git push
```

`git revert` crea un commit nuevo que anula el anterior, sin borrar el historial. Si se abre un editor, escribe `:wq` y Enter. También se pueden revisar los cambios en GitHub, en el enlace **Commits** del repositorio.

## Pausar la sincronización

| Acción | Comando |
| --- | --- |
| Pausar | `systemctl --user stop vault-sync.timer` |
| Reanudar | `systemctl --user start vault-sync.timer` |
| Desactivar al arrancar | `systemctl --user disable vault-sync.timer` |
| Forzar una sincronización ahora | `~/sync-vault.sh` |

## Rotar la clave del API

Hazlo si la clave se ha compartido o expuesto en algún sitio.

```bash
openssl rand -hex 32
```

```bash
nano ~/.hermes/.env
```

Sustituye el valor de `API_SERVER_KEY`, guarda y reinicia el gateway. Después copia la clave nueva a Workspace y compruébala:

```bash
key=$(grep '^API_SERVER_KEY=' ~/.hermes/.env | cut -d= -f2-); sed -i "s|^HERMES_API_TOKEN=.*|HERMES_API_TOKEN=$key|" ~/hermes-workspace/.env
```

```bash
a=$(grep '^API_SERVER_KEY=' ~/.hermes/.env | cut -d= -f2-); b=$(grep '^HERMES_API_TOKEN=' ~/hermes-workspace/.env | cut -d= -f2-); [ "$a" = "$b" ] && echo IGUALES || echo DISTINTAS
```

```bash
systemctl --user restart hermes-workspace
```

Si en **Settings → Connection** de Workspace hay un token guardado, actualízalo también.

## Cambiar la contraseña de la interfaz

```bash
openssl rand -hex 24
```

Sustituye `HERMES_PASSWORD` en `~/hermes-workspace/.env` y reinicia con `systemctl --user restart hermes-workspace`.

## Buenas prácticas

- No edites la misma nota que Hermes está modificando.
- Abre Obsidian con internet para que **Pull on startup** traiga los cambios pendientes.
- Guarda solo el vault en la raíz del repositorio: todo lo que haya ahí se sube a GitHub.
- No guardes contraseñas ni datos financieros en el vault.
- GitHub rechaza archivos de más de 100 MB: excluye PDFs o vídeos pesados en el `.gitignore`.
- Nunca publiques `API_SERVER_KEY`, `HERMES_PASSWORD` ni la llave privada `~/.ssh/vault_key`.
- Mantén otra vía de acceso a Hermes (Telegram o la terminal) por si la interfaz falla.

[← Anterior: Decisiones de diseño](08-decisiones-de-diseno.md) · [Índice](../../README.es.md)

# 3. Sincronización en el LXC

🌐 [English](../en/03-lxc-sync.md) · **Español**

[← Anterior: Vault y GitHub](02-vault-y-github.md) · [Índice](../../README.es.md) · [Siguiente: Conectar Hermes al vault →](04-hermes-y-obsidian.md)

En esta parte el contenedor obtiene acceso al repositorio con una **deploy key**, clona el vault y lo sincroniza automáticamente cada 5 minutos. Todo se hace en la consola xterm.js del contenedor, como usuario `hermes`.

## 3.1 Generar la deploy key

Una deploy key es una llave SSH con acceso a **un solo repositorio**, no a toda la cuenta de GitHub.

```bash
ssh-keygen -t ed25519 -C "hermes-lxc" -f ~/.ssh/vault_key -N ""
```

```bash
ls ~/.ssh
```

Deben aparecer `vault_key` (privada, nunca sale del contenedor) y `vault_key.pub` (pública, la que se pega en GitHub). Si no aparecen, probablemente generaste la llave como `root`.

## 3.2 Copiar la llave pública

```bash
cat ~/.ssh/vault_key.pub
```

El resultado es **una sola línea**:

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI...(muchos caracteres)... hermes-lxc
```

Cópiala completa desde la consola xterm.js. No confundas la llave con otros textos:

| Texto | Qué es | ¿Va en GitHub? |
| --- | --- | --- |
| `ssh-ed25519 AAAA... hermes-lxc` | Llave pública | Sí |
| `SHA256:...` | Huella (resumen de la llave) | No |
| `-----BEGIN OPENSSH PRIVATE KEY-----` | Llave privada | Nunca |

Para comprobar que la llave es válida:

```bash
ssh-keygen -l -f ~/.ssh/vault_key.pub
```

Debe responder algo como `256 SHA256:... hermes-lxc (ED25519)`. Eso es la huella: confirma que la llave está bien, pero no es lo que se pega en GitHub (ver [E7](07-solucion-de-problemas.md#e7-aparece-sha256-en-lugar-de-la-llave)).

## 3.3 Añadir la llave en GitHub

1. Repositorio `<repo-vault>` → **Settings → Deploy keys → Add deploy key**.
2. Title: `Hermes LXC`.
3. Key: la línea `ssh-ed25519 ...` completa.
4. Marca **Allow write access** para que Hermes pueda subir cambios.
5. **Add key**.

## 3.4 Configurar SSH

El archivo `~/.ssh/config` crea un alias (`github-vault`) que le dice a SSH qué llave usar. Créalo con nano; pegar bloques con `<< 'EOF'` en una sola línea no funciona (ver [E5](07-solucion-de-problemas.md#e5-el-bloque-con-eof-no-funciona)).

```bash
nano ~/.ssh/config
```

```
Host github-vault
  HostName github.com
  User git
  IdentityFile ~/.ssh/vault_key
  IdentitiesOnly yes
```

Guarda con **Ctrl+O**, **Enter**, y sal con **Ctrl+X**. Plantilla: [`config/ssh_config.example`](../../config/ssh_config.example).

| Línea | Función |
| --- | --- |
| `Host github-vault` | Nombre del alias |
| `HostName github.com` | Servidor real |
| `User git` | Usuario que GitHub usa siempre para SSH |
| `IdentityFile ~/.ssh/vault_key` | Llave privada a usar |
| `IdentitiesOnly yes` | Evita que SSH pruebe otras llaves |

SSH rechaza configuraciones que otros usuarios puedan leer:

```bash
chmod 600 ~/.ssh/config
```

## 3.5 Probar la conexión

```bash
ssh -T github-vault
```

La primera vez aparece:

```
The authenticity of host 'github.com (...)' can't be established.
ED25519 key fingerprint is SHA256:....
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

Compara la huella con la huella ED25519 oficial que GitHub publica en su documentación (`SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU`). Si coincide, escribe `yes`. La huella queda guardada en `~/.ssh/known_hosts` y no vuelve a preguntar, algo necesario para que el script automático funcione.

Respuesta esperada:

```
Hi <usuario-github>/<repo-vault>! You've successfully authenticated, but GitHub does not provide shell access.
```

Ese mensaje confirma **el usuario y el repositorio exactos** que hay que usar en el clone. "Does not provide shell access" es normal.

## 3.6 Clonar el repositorio

En la dirección va el nombre del **repositorio de GitHub**, no el del vault. Si una carpeta `~/vault` quedó vacía de un intento anterior, bórrala primero con `rm -rf ~/vault` (ver [E16](07-solucion-de-problemas.md#e16-ls-vault-no-muestra-nada)).

```bash
git clone github-vault:<usuario-github>/<repo-vault>.git ~/vault
```

Configura la identidad de Hermes para que sus commits se distingan en el historial:

```bash
cd ~/vault
```

```bash
git config user.name "Hermes"
```

```bash
git config user.email "hermes@lxc.local"
```

Comprueba:

```bash
ls ~/vault
```

```bash
ls ~/vault/<nombre-vault>
```

En el segundo deben aparecer las notas. La ruta del vault para Hermes es `/home/hermes/vault/<nombre-vault>`.

| Nombre | Dónde existe | Para qué |
| --- | --- | --- |
| `<repo-vault>` | GitHub | Comandos de Git (clone, remote) |
| `<nombre-vault>` | Carpeta del vault | Ruta que usa Hermes |
| `~/vault` | Contenedor | Carpeta de la copia del repositorio |

## 3.7 Script de sincronización

```bash
nano ~/sync-vault.sh
```

```bash
#!/bin/bash
cd ~/vault || exit 1
git pull --rebase --autostash -q
git add -A
if ! git diff --cached --quiet; then
  git commit -q -m "Hermes: $(date '+%Y-%m-%d %H:%M')"
  git push -q
fi
```

| Línea | Función |
| --- | --- |
| `cd ~/vault \|\| exit 1` | Entra en el repositorio o se detiene |
| `git pull --rebase --autostash -q` | Descarga cambios, apartando temporalmente los locales |
| `git add -A` | Prepara archivos nuevos, modificados y borrados |
| `if ! git diff --cached --quiet` | Solo continúa si hay algo que subir |
| `git commit ... "Hermes: <fecha>"` | Guarda con un mensaje que identifica a Hermes |
| `git push -q` | Sube a GitHub |

Hazlo ejecutable (no muestra nada si funciona):

```bash
chmod +x ~/sync-vault.sh
```

```bash
ls -l ~/sync-vault.sh
```

La línea debe empezar por `-rwxr-xr-x`. Copia en el repositorio: [`scripts/sync-vault.sh`](../../scripts/sync-vault.sh).

## 3.8 Prueba de ida y vuelta

**Del contenedor a Obsidian:**

```bash
echo "Hola desde Hermes" > ~/vault/<nombre-vault>/prueba-hermes.md
```

```bash
~/sync-vault.sh
```

En Obsidian, **Ctrl+P → Git: Pull**: debe aparecer `prueba-hermes`.

**De Obsidian al contenedor:** edita la nota en Obsidian, ejecuta **Git: Commit-and-sync** y luego en el contenedor:

```bash
~/sync-vault.sh
```

```bash
cat ~/vault/<nombre-vault>/prueba-hermes.md
```

Si aparece el texto escrito en Obsidian, funciona en ambos sentidos.

## 3.9 Automatizar con systemd

```bash
mkdir -p ~/.config/systemd/user
```

**Servicio** (qué se ejecuta):

```bash
nano ~/.config/systemd/user/vault-sync.service
```

```
[Unit]
Description=Sincronizar vault de Obsidian

[Service]
Type=oneshot
ExecStart=%h/sync-vault.sh
```

**Timer** (cada cuánto):

```bash
nano ~/.config/systemd/user/vault-sync.timer
```

```
[Unit]
Description=Sincronizar vault cada 5 minutos

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
```

Copias en el repositorio: [`systemd/`](../../systemd/).

Actívalo:

```bash
systemctl --user daemon-reload
```

```bash
systemctl --user enable --now vault-sync.timer
```

## 3.10 Activar linger

Sin *linger*, los servicios de usuario se detienen al cerrar la consola. Hazlo como `root` (si `hermes` no tiene sudo, `sudo loginctl` falla):

```bash
exit
```

```bash
loginctl enable-linger hermes
```

```bash
su - hermes
```

## Comprobación

```bash
systemctl --user list-timers
```

Debe aparecer `vault-sync.timer` con la próxima ejecución en la columna **NEXT**.

```bash
journalctl --user -u vault-sync.service -n 20
```

Deben aparecer líneas `Finished Sincronizar vault de Obsidian` (o la descripción que hayas puesto en el servicio).

Prueba final: edita una nota en Obsidian, espera unos 10 minutos sin tocar nada y comprueba en el contenedor que el cambio llegó solo.

[← Anterior: Vault y GitHub](02-vault-y-github.md) · [Índice](../../README.es.md) · [Siguiente: Conectar Hermes al vault →](04-hermes-y-obsidian.md)

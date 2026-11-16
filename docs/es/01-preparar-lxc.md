# 1. Preparar el contenedor LXC

🌐 [English](../en/01-prepare-lxc.md) · **Español**

[← Volver al índice](../../README.es.md) · [Siguiente: Vault de Obsidian y GitHub →](02-vault-y-github.md)

En esta parte se crea el contenedor y se prepara el usuario `hermes`, que es con el que se ejecuta todo lo demás.

## 1.1 Crear el contenedor

1. En Proxmox, descarga la plantilla de Ubuntu: **Datacenter → nodo → CT Templates → Templates** y elige `ubuntu-24.04-standard`.
2. Pulsa **Create CT** y usa estos valores:

| Ajuste | Valor usado | Motivo |
| --- | --- | --- |
| Hostname | `hermesagent` | Nombre que aparecerá en Tailscale |
| Unprivileged container | Activado | Más seguro |
| CPU | 2 núcleos | La inferencia ocurre en OpenRouter, no aquí |
| Memoria | 4096 MB | Hermes Workspace necesita memoria para compilar |
| Swap | 1024 MB | Margen durante la compilación |
| Disco | 20 GB | Hermes, Node.js, Workspace y el vault |

3. Después de crearlo, en **Options → Features** activa `nesting`. Es necesario para que systemd funcione bien dentro del contenedor.

## 1.2 Abrir la consola correcta

Usa siempre la consola **xterm.js**: selecciona el contenedor, abre el desplegable junto a **Console** y elige **xterm.js**.

La consola por defecto (noVNC) muestra la pantalla como una imagen y corrompe el texto que copias. Fue la causa del error `Key is invalid` al pegar la llave SSH en GitHub (ver [solución de problemas](07-solucion-de-problemas.md#e6-key-is-invalid-al-pegar-la-llave-en-github)).

- Para pegar en xterm.js: **Ctrl+Shift+V** o clic derecho → Pegar.
- **No uses Ctrl+W dentro de nano en la consola web**: el navegador lo interpreta como "cerrar pestaña". Para buscar en nano, usa **F6**.

Alternativa: en el **nodo** (el servidor, no el contenedor) abre **Shell** y ejecuta `pct enter <ID>`. Entras como `root` sin pedir contraseña.

## 1.3 Leer la línea de comandos

```
hermes@hermesagent:~/vault$
```

| Parte | Significado |
| --- | --- |
| `hermes` | Usuario actual. Si dice `root`, eres administrador |
| `hermesagent` | Nombre del contenedor |
| `~/vault` | Carpeta actual. `~` es la carpeta personal (`/home/hermes`) |
| `$` | Usuario normal. `#` indica `root` |

Para volver a la carpeta personal, escribe `cd`.

En Linux, **un comando que no muestra nada casi siempre funcionó**. Solo aparece texto cuando hay un error o cuando el comando debe mostrar información.

## 1.4 Crear el usuario hermes

Como `root`:

```bash
adduser hermes
```

```bash
usermod -aG sudo hermes
```

El segundo comando da permisos de administrador. Sin él, cualquier `sudo` falla con `hermes is not in the sudoers file` (ver [E1](07-solucion-de-problemas.md#e1-hermes-is-not-in-the-sudoers-file)).

Si olvidas la contraseña de `hermes`, cámbiala como `root` sin necesitar la anterior. Mientras escribes no se ven caracteres; es normal:

```bash
passwd hermes
```

Cámbiate al usuario y comprueba que pertenece al grupo `sudo`:

```bash
su - hermes
```

```bash
groups
```

Si no aparece `sudo`, sal con `exit` y vuelve a entrar con `su - hermes`: los grupos se aplican al iniciar sesión.

## 1.5 Instalar herramientas básicas

Como `hermes`:

```bash
sudo apt update && sudo apt upgrade -y
```

```bash
sudo apt install -y git openssh-client nano curl
```

## Comprobación

- La línea de comandos muestra `hermes@hermesagent:~$`.
- `groups` incluye `sudo`.
- `git --version` muestra una versión.

[← Volver al índice](../../README.es.md) · [Siguiente: Vault de Obsidian y GitHub →](02-vault-y-github.md)

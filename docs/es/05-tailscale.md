# 5. Tailscale en el LXC

🌐 [English](../en/05-tailscale.md) · **Español**

[← Anterior: Conectar Hermes al vault](04-hermes-y-obsidian.md) · [Índice](../../README.es.md) · [Siguiente: Hermes Workspace →](06-hermes-workspace.md)

Tailscale crea una red privada entre tus dispositivos, sin abrir puertos en el router. En esta parte el contenedor se une a esa red para que la interfaz de Hermes sea accesible desde el móvil o el PC en cualquier lugar.

## Por qué instalarlo dentro del contenedor

Aunque Tailscale ya esté instalado en otra máquina de la red (el host de Proxmox u otro servidor), **cada máquina necesita su propia instalación**. El comando `tailscale serve`, que publica la interfaz con HTTPS, solo puede publicar servicios **de la máquina donde se ejecuta**. Ejecutarlo en otra máquina no funciona (ver [E20](07-solucion-de-problemas.md#e20-sudo-tailscale-command-not-found) y [E21](07-solucion-de-problemas.md#e21-usar-tailscale-desde-otra-máquina)).

Instalarlo en el contenedor también hace que el acceso a Hermes no dependa de que otra máquina esté encendida.

## 5.1 Dar acceso al dispositivo de red (host de Proxmox)

Los contenedores LXC sin privilegios no tienen acceso por defecto al dispositivo `/dev/net/tun` que Tailscale necesita.

En Proxmox, selecciona el **nodo** → **Shell** y edita la configuración del contenedor:

```bash
nano /etc/pve/lxc/<ID>.conf
```

Añade al final:

```
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file
```

Plantilla: [`config/lxc-tun.conf.example`](../../config/lxc-tun.conf.example). Reinicia el contenedor:

```bash
pct reboot <ID>
```

## 5.2 Comprobar el dispositivo (contenedor)

```bash
ls -l /dev/net/tun
```

Debe aparecer una línea que empieza por `crw`. Si dice "No such file or directory", revisa las dos líneas del paso anterior.

## 5.3 Instalar y conectar Tailscale

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

```bash
sudo tailscale up --hostname=hermesagent
```

Aparece un enlace `https://login.tailscale.com/...`. Ábrelo en el navegador e inicia sesión con **la misma cuenta** que el resto de tus dispositivos. El comando termina solo al autorizarlo.

```bash
tailscale status
```

Debe aparecer `hermesagent` junto a tus otros dispositivos.

## 5.4 Desactivar la caducidad de la llave

Tailscale caduca la autorización de cada dispositivo periódicamente (unos 180 días por defecto). Para un servidor que debe estar siempre disponible:

Panel de administración de Tailscale → **Machines** → `hermesagent` → menú **⋯** → **Disable key expiry**.

## 5.5 Activar HTTPS

Panel de administración → **DNS** → activa **MagicDNS** y **HTTPS Certificates**. Es necesario para publicar la interfaz con una dirección del tipo `https://hermesagent.<tu-tailnet>.ts.net` en la siguiente parte.

## 5.6 Dispositivos cliente

Instala la app de Tailscale en el móvil y el PC, con la misma cuenta. Para que la interfaz de Hermes funcione como una app sin tener que conectar la VPN cada vez:

| Sistema | Ajuste |
| --- | --- |
| Android | Ajustes → Redes → VPN → Tailscale → **VPN siempre activa** |
| iPhone | App de Tailscale → **VPN On Demand** |

## Comprobación

- `tailscale status` en el contenedor muestra la lista de dispositivos.
- Desde el móvil, con Tailscale conectado, `hermesagent` aparece en la app.

[← Anterior: Conectar Hermes al vault](04-hermes-y-obsidian.md) · [Índice](../../README.es.md) · [Siguiente: Hermes Workspace →](06-hermes-workspace.md)

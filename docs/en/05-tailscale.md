# 5. Tailscale in the LXC

🌐 **English** · [Español](../es/05-tailscale.md)

[← Previous: Connect Hermes to the vault](04-hermes-and-obsidian.md) · [Index](../../README.md) · [Next: Hermes Workspace →](06-hermes-workspace.md)

Tailscale builds a private network between your devices without opening ports on the router. In this part the container joins that network so the Hermes interface is reachable from a phone or PC anywhere.

## Why install it inside the container

Even if Tailscale is already installed on another machine on the network (the Proxmox host or another server), **each machine needs its own installation**. The `tailscale serve` command, which publishes the interface over HTTPS, can only publish services **on the machine where it runs**. Running it on another machine doesn't work (see [E20](07-troubleshooting.md#e20-sudo-tailscale-command-not-found) and [E21](07-troubleshooting.md#e21-using-tailscale-from-another-machine)).

Installing it in the container also means access to Hermes doesn't depend on another machine being on.

## 5.1 Give access to the network device (Proxmox host)

Unprivileged LXC containers have no access by default to the `/dev/net/tun` device Tailscale needs.

In Proxmox, select the **node** → **Shell** and edit the container configuration:

```bash
nano /etc/pve/lxc/<ID>.conf
```

Add at the end:

```
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file
```

Template: [`config/lxc-tun.conf.example`](../../config/lxc-tun.conf.example). Restart the container:

```bash
pct reboot <ID>
```

## 5.2 Check the device (container)

```bash
ls -l /dev/net/tun
```

A line starting with `crw` should appear. If it says "No such file or directory", review the two lines from the previous step.

## 5.3 Install and connect Tailscale

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

```bash
sudo tailscale up --hostname=hermesagent
```

A `https://login.tailscale.com/...` link appears. Open it in the browser and sign in with **the same account** as your other devices. The command finishes on its own once you authorize it.

```bash
tailscale status
```

`hermesagent` should appear next to your other devices.

## 5.4 Disable key expiry

Tailscale expires each device's authorization periodically (about 180 days by default). For a server that should always be available:

Tailscale admin console → **Machines** → `hermesagent` → **⋯** menu → **Disable key expiry**.

## 5.5 Enable HTTPS

Admin console → **DNS** → enable **MagicDNS** and **HTTPS Certificates**. It's required to publish the interface at an address like `https://hermesagent.<your-tailnet>.ts.net` in the next part.

## 5.6 Client devices

Install the Tailscale app on your phone and PC, with the same account. So the Hermes interface works like an app without connecting the VPN every time:

| System | Setting |
| --- | --- |
| Android | Settings → Network → VPN → Tailscale → **Always-on VPN** |
| iPhone | Tailscale app → **VPN On Demand** |

## Check

- `tailscale status` in the container lists your devices.
- On the phone, with Tailscale connected, `hermesagent` shows up in the app.

[← Previous: Connect Hermes to the vault](04-hermes-and-obsidian.md) · [Index](../../README.md) · [Next: Hermes Workspace →](06-hermes-workspace.md)

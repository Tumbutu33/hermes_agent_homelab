# 1. Prepare the LXC container

🌐 **English** · [Español](../es/01-preparar-lxc.md)

[← Back to index](../../README.md) · [Next: Obsidian vault and GitHub →](02-vault-and-github.md)

This part creates the container and prepares the `hermes` user, which runs everything else.

## 1.1 Create the container

1. In Proxmox, download the Ubuntu template: **Datacenter → node → CT Templates → Templates** and pick `ubuntu-24.04-standard`.
2. Click **Create CT** and use these values:

| Setting | Value used | Reason |
| --- | --- | --- |
| Hostname | `hermesagent` | Name that will show up in Tailscale |
| Unprivileged container | Enabled | More secure |
| CPU | 2 cores | Inference happens on OpenRouter, not here |
| Memory | 4096 MB | Hermes Workspace needs memory to build |
| Swap | 1024 MB | Headroom during the build |
| Disk | 20 GB | Hermes, Node.js, Workspace and the vault |

3. After creating it, enable `nesting` under **Options → Features**. systemd needs it to work properly inside the container.

## 1.2 Open the right console

Always use the **xterm.js** console: select the container, open the dropdown next to **Console** and choose **xterm.js**.

The default console (noVNC) displays the screen as an image and corrupts copied text. It caused the `Key is invalid` error when pasting the SSH key into GitHub (see [troubleshooting](07-troubleshooting.md#e6-key-is-invalid-when-pasting-the-key-into-github)).

- To paste in xterm.js: **Ctrl+Shift+V** or right click → Paste.
- **Don't use Ctrl+W inside nano in the web console**: the browser reads it as "close tab". To search in nano, use **F6**.

Alternative: on the **node** (the server, not the container) open **Shell** and run `pct enter <ID>`. You get in as `root` without a password.

## 1.3 Read the command prompt

```
hermes@hermesagent:~/vault$
```

| Part | Meaning |
| --- | --- |
| `hermes` | Current user. If it says `root`, you're the administrator |
| `hermesagent` | Container name |
| `~/vault` | Current folder. `~` is the home folder (`/home/hermes`) |
| `$` | Regular user. `#` means `root` |

To go back to the home folder, type `cd`.

In Linux, **a command that prints nothing almost always worked**. Output only appears when there's an error or when the command is meant to show information.

## 1.4 Create the hermes user

As `root`:

```bash
adduser hermes
```

```bash
usermod -aG sudo hermes
```

The second command grants administrator rights. Without it, any `sudo` fails with `hermes is not in the sudoers file` (see [E1](07-troubleshooting.md#e1-hermes-is-not-in-the-sudoers-file)).

If you forget the `hermes` password, change it as `root` without needing the old one. Nothing shows on screen while you type; that's normal:

```bash
passwd hermes
```

Switch to the user and check that it belongs to the `sudo` group:

```bash
su - hermes
```

```bash
groups
```

If `sudo` doesn't appear, leave with `exit` and log back in with `su - hermes`: groups are applied at login.

## 1.5 Install basic tools

As `hermes`:

```bash
sudo apt update && sudo apt upgrade -y
```

```bash
sudo apt install -y git openssh-client nano curl
```

## Check

- The prompt shows `hermes@hermesagent:~$`.
- `groups` includes `sudo`.
- `git --version` prints a version.

[← Back to index](../../README.md) · [Next: Obsidian vault and GitHub →](02-vault-and-github.md)

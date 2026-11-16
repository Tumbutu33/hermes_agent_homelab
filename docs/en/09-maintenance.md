# 9. Maintenance

🌐 **English** · [Español](../es/09-mantenimiento.md)

[← Previous: Design decisions](08-design-decisions.md) · [Index](../../README.md)

Routine tasks to keep the system up to date, check its health and recover from mistakes. Every command runs in the container as `hermes`, unless stated otherwise.

## Check the status

| To find out… | Command |
| --- | --- |
| Overall Hermes status | `curl http://127.0.0.1:9119/api/status` (look for `"overall":"ok"`) |
| Whether the gateway responds | `curl http://127.0.0.1:8642/health` |
| Whether Workspace is running | `systemctl --user status hermes-workspace` |
| Whether the vault timer is active | `systemctl --user list-timers` |
| Latest syncs | `journalctl --user -u vault-sync.service -n 20` |
| Pending changes in the vault | `cd ~/vault && git status` |
| Latest vault commits | `cd ~/vault && git log --oneline -5` |
| Devices on Tailscale | `tailscale status` |
| Published address | `tailscale serve status` |

## Update Hermes

```bash
hermes update
```

Then restart the dashboard and the gateway so they use the new version:

```bash
systemctl --user restart hermes-dashboard
```

```bash
systemctl --user list-units | grep -i hermes
```

```bash
systemctl --user restart <gateway-service-name>
```

Or reboot the container from Proxmox. Check with `curl http://127.0.0.1:9119/api/status`.

## Update Hermes Workspace

Updating from the terminal is better than using the notice in the interface: you can see the errors.

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

`.env` isn't part of the Workspace repository, so `git pull` leaves it alone. If `git pull` complains about other local changes, review them with `git status` before continuing.

Updates don't affect the vault, the GitHub sync or Hermes's memory.

## Backups

| What | Where it lives | Backup |
| --- | --- | --- |
| Obsidian vault | PC, GitHub and container | Already backed up on GitHub, with history |
| Hermes memory, skills and configuration | `~/.hermes` in the container | Container backup in Proxmox |
| Workspace configuration | `~/hermes-workspace/.env` | Container backup in Proxmox |

Before major updates, back up the container: Proxmox → container → **Backup → Backup now**. If the storage supports it (for example, ZFS or LVM-thin), a **Snapshot** is even faster to create and restore.

## Undo a Hermes change in the vault

Every change is kept in the history, so nothing is lost.

```bash
cd ~/vault
```

```bash
git log --oneline -10
```

Copy the hash of the commit to undo (for example, `a1b2c3d`):

```bash
git revert a1b2c3d
```

```bash
git push
```

`git revert` creates a new commit that cancels the previous one, without rewriting history. If an editor opens, type `:wq` and Enter. Changes can also be reviewed on GitHub, through the repository's **Commits** link.

## Pause the sync

| Action | Command |
| --- | --- |
| Pause | `systemctl --user stop vault-sync.timer` |
| Resume | `systemctl --user start vault-sync.timer` |
| Disable at boot | `systemctl --user disable vault-sync.timer` |
| Force a sync now | `~/sync-vault.sh` |

## Rotate the API key

Do it if the key has been shared or exposed anywhere.

```bash
openssl rand -hex 32
```

```bash
nano ~/.hermes/.env
```

Replace the `API_SERVER_KEY` value, save and restart the gateway. Then copy the new key to Workspace and check it:

```bash
key=$(grep '^API_SERVER_KEY=' ~/.hermes/.env | cut -d= -f2-); sed -i "s|^HERMES_API_TOKEN=.*|HERMES_API_TOKEN=$key|" ~/hermes-workspace/.env
```

```bash
a=$(grep '^API_SERVER_KEY=' ~/.hermes/.env | cut -d= -f2-); b=$(grep '^HERMES_API_TOKEN=' ~/hermes-workspace/.env | cut -d= -f2-); [ "$a" = "$b" ] && echo EQUAL || echo DIFFERENT
```

```bash
systemctl --user restart hermes-workspace
```

If there's a token saved under **Settings → Connection** in Workspace, update it too.

## Change the interface password

```bash
openssl rand -hex 24
```

Replace `HERMES_PASSWORD` in `~/hermes-workspace/.env` and restart with `systemctl --user restart hermes-workspace`.

## Good practices

- Don't edit a note Hermes is modifying.
- Open Obsidian with an internet connection so **Pull on startup** brings in pending changes.
- Keep only the vault at the repository root: everything there is pushed to GitHub.
- Don't store passwords or financial data in the vault.
- GitHub rejects files larger than 100 MB: exclude heavy PDFs or videos in the `.gitignore`.
- Never publish `API_SERVER_KEY`, `HERMES_PASSWORD` or the private key `~/.ssh/vault_key`.
- Keep another way to reach Hermes (Telegram or the terminal) in case the interface fails.

[← Previous: Design decisions](08-design-decisions.md) · [Index](../../README.md)

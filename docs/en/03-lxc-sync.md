# 3. Sync in the LXC

🌐 **English** · [Español](../es/03-sincronizacion-lxc.md)

[← Previous: Vault and GitHub](02-vault-and-github.md) · [Index](../../README.md) · [Next: Connect Hermes to the vault →](04-hermes-and-obsidian.md)

In this part the container gets access to the repository with a **deploy key**, clones the vault and syncs it automatically every 5 minutes. Everything happens in the container's xterm.js console, as the `hermes` user.

## 3.1 Generate the deploy key

A deploy key is an SSH key with access to **a single repository**, not to the whole GitHub account.

```bash
ssh-keygen -t ed25519 -C "hermes-lxc" -f ~/.ssh/vault_key -N ""
```

```bash
ls ~/.ssh
```

You should see `vault_key` (private, never leaves the container) and `vault_key.pub` (public, the one that goes into GitHub). If they don't show up, you probably generated the key as `root`.

## 3.2 Copy the public key

```bash
cat ~/.ssh/vault_key.pub
```

The output is **a single line**:

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI...(many characters)... hermes-lxc
```

Copy all of it from the xterm.js console. Don't confuse the key with other text:

| Text | What it is | Goes into GitHub? |
| --- | --- | --- |
| `ssh-ed25519 AAAA... hermes-lxc` | Public key | Yes |
| `SHA256:...` | Fingerprint (key summary) | No |
| `-----BEGIN OPENSSH PRIVATE KEY-----` | Private key | Never |

To check the key is valid:

```bash
ssh-keygen -l -f ~/.ssh/vault_key.pub
```

It should reply with something like `256 SHA256:... hermes-lxc (ED25519)`. That's the fingerprint: it confirms the key is fine, but it's not what you paste into GitHub (see [E7](07-troubleshooting.md#e7-sha256-shows-up-instead-of-the-key)).

## 3.3 Add the key on GitHub

1. Repository `<vault-repo>` → **Settings → Deploy keys → Add deploy key**.
2. Title: `Hermes LXC`.
3. Key: the full `ssh-ed25519 ...` line.
4. Check **Allow write access** so Hermes can push changes.
5. **Add key**.

## 3.4 Configure SSH

The `~/.ssh/config` file creates an alias (`github-vault`) that tells SSH which key to use. Create it with nano; pasting `<< 'EOF'` blocks on a single line doesn't work (see [E5](07-troubleshooting.md#e5-the-eof-block-doesnt-work)).

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

Save with **Ctrl+O**, **Enter**, and exit with **Ctrl+X**. Template: [`config/ssh_config.example`](../../config/ssh_config.example).

| Line | Purpose |
| --- | --- |
| `Host github-vault` | Alias name |
| `HostName github.com` | Real server |
| `User git` | The user GitHub always uses for SSH |
| `IdentityFile ~/.ssh/vault_key` | Private key to use |
| `IdentitiesOnly yes` | Stops SSH from trying other keys |

SSH rejects configuration files other users can read:

```bash
chmod 600 ~/.ssh/config
```

## 3.5 Test the connection

```bash
ssh -T github-vault
```

The first time you'll see:

```
The authenticity of host 'github.com (...)' can't be established.
ED25519 key fingerprint is SHA256:....
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

Compare the fingerprint with the official ED25519 fingerprint GitHub publishes in its documentation (`SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU`). If it matches, type `yes`. The fingerprint is stored in `~/.ssh/known_hosts` and you won't be asked again, which the automatic script needs.

Expected reply:

```
Hi <github-user>/<vault-repo>! You've successfully authenticated, but GitHub does not provide shell access.
```

That message confirms **the exact user and repository** to use in the clone. "Does not provide shell access" is normal.

## 3.6 Clone the repository

The URL takes the **GitHub repository** name, not the vault name. If an empty `~/vault` folder was left over from an earlier attempt, delete it first with `rm -rf ~/vault` (see [E16](07-troubleshooting.md#e16-ls-vault-shows-nothing)).

```bash
git clone github-vault:<github-user>/<vault-repo>.git ~/vault
```

Set Hermes's identity so its commits stand out in the history:

```bash
cd ~/vault
```

```bash
git config user.name "Hermes"
```

```bash
git config user.email "hermes@lxc.local"
```

Check:

```bash
ls ~/vault
```

```bash
ls ~/vault/<vault-name>
```

The second one should list the notes. The vault path for Hermes is `/home/hermes/vault/<vault-name>`.

| Name | Where it exists | What it's for |
| --- | --- | --- |
| `<vault-repo>` | GitHub | Git commands (clone, remote) |
| `<vault-name>` | Vault folder | Path Hermes uses |
| `~/vault` | Container | Folder holding the repository copy |

## 3.7 Sync script

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

| Line | Purpose |
| --- | --- |
| `cd ~/vault \|\| exit 1` | Enters the repository or stops |
| `git pull --rebase --autostash -q` | Pulls changes, temporarily stashing local ones |
| `git add -A` | Stages new, modified and deleted files |
| `if ! git diff --cached --quiet` | Only continues if there's something to push |
| `git commit ... "Hermes: <date>"` | Commits with a message that identifies Hermes |
| `git push -q` | Pushes to GitHub |

Make it executable (it prints nothing when it works):

```bash
chmod +x ~/sync-vault.sh
```

```bash
ls -l ~/sync-vault.sh
```

The line should start with `-rwxr-xr-x`. Copy in this repository: [`scripts/sync-vault.sh`](../../scripts/sync-vault.sh).

## 3.8 Round-trip test

**From the container to Obsidian:**

```bash
echo "Hello from Hermes" > ~/vault/<vault-name>/hermes-test.md
```

```bash
~/sync-vault.sh
```

In Obsidian, **Ctrl+P → Git: Pull**: `hermes-test` should appear.

**From Obsidian to the container:** edit the note in Obsidian, run **Git: Commit-and-sync**, then in the container:

```bash
~/sync-vault.sh
```

```bash
cat ~/vault/<vault-name>/hermes-test.md
```

If the text you wrote in Obsidian shows up, sync works both ways.

## 3.9 Automate with systemd

```bash
mkdir -p ~/.config/systemd/user
```

**Service** (what runs):

```bash
nano ~/.config/systemd/user/vault-sync.service
```

```
[Unit]
Description=Sync Obsidian vault

[Service]
Type=oneshot
ExecStart=%h/sync-vault.sh
```

**Timer** (how often):

```bash
nano ~/.config/systemd/user/vault-sync.timer
```

```
[Unit]
Description=Sync Obsidian vault every 5 minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
```

Copies in this repository: [`systemd/`](../../systemd/).

Enable it:

```bash
systemctl --user daemon-reload
```

```bash
systemctl --user enable --now vault-sync.timer
```

## 3.10 Enable linger

Without *linger*, user services stop when you close the console. Do it as `root` (if `hermes` has no sudo rights, `sudo loginctl` fails):

```bash
exit
```

```bash
loginctl enable-linger hermes
```

```bash
su - hermes
```

## Check

```bash
systemctl --user list-timers
```

`vault-sync.timer` should appear with its next run in the **NEXT** column.

```bash
journalctl --user -u vault-sync.service -n 20
```

You should see `Finished Sync Obsidian vault` lines (or whatever description you gave the service).

Final test: edit a note in Obsidian, wait about 10 minutes without touching anything and check in the container that the change arrived on its own.

[← Previous: Vault and GitHub](02-vault-and-github.md) · [Index](../../README.md) · [Next: Connect Hermes to the vault →](04-hermes-and-obsidian.md)

# 7. Troubleshooting

🌐 **English** · [Español](../es/07-solucion-de-problemas.md)

[← Previous: Hermes Workspace](06-hermes-workspace.md) · [Index](../../README.md) · [Next: Design decisions →](08-design-decisions.md)

This guide collects **every error that came up during the real installation**, in the order they appeared, with the exact message, the cause and the fix. At the end there's a section with other likely errors that didn't happen but are worth knowing.

## Summary

| # | Stage | Symptom |
| --- | --- | --- |
| [E1](#e1-hermes-is-not-in-the-sudoers-file) | Container | `hermes is not in the sudoers file` |
| [E2](#e2-i-forgot-the-hermes-password) | Container | Forgotten `hermes` password |
| [E3](#e3-a-command-prints-nothing) | Container | `chmod` and other commands print nothing |
| [E4](#e4-ctrlw-closes-the-proxmox-console) | Container | Ctrl+W in nano closes the console |
| [E5](#e5-the-eof-block-doesnt-work) | Container | `<< 'EOF'` blocks don't work |
| [E6](#e6-key-is-invalid-when-pasting-the-key-into-github) | Deploy key | `Key is invalid. You must supply a key in OpenSSH public key format` |
| [E7](#e7-sha256-shows-up-instead-of-the-key) | Deploy key | `SHA256:...` shows up instead of the key |
| [E8](#e8-the-authenticity-of-host-githubcom-cant-be-established) | SSH | Authenticity prompt for `github.com` |
| [E9](#e9-repository-not-found-when-cloning-in-the-container) | Clone | `ERROR: Repository not found` in the container |
| [E10](#e10-repository-name-or-vault-name) | Clone | Repo name vs. vault name confusion |
| [E11](#e11-the-notes-dont-show-up-on-github) | PC | The notes don't show up on GitHub |
| [E12](#e12-select-or-create-a-new-remote) | PC | Remote picker in Obsidian |
| [E13](#e13-no-changes-to-commit) | PC | `No changes to commit` |
| [E14](#e14-repository-not-found-from-obsidian) | PC | `Repository not found` with the placeholder URL |
| [E15](#e15-push-rejected-because-of-unrelated-histories) | PC | Push rejected because of the GitHub README |
| [E16](#e16-ls-vault-shows-nothing) | Clone | `ls ~/vault` is empty |
| [E17](#e17-the-repo-contains-a-subfolder-and-desktopini) | Clone | A subfolder and `desktop.ini` show up |
| [E18](#e18-the-gitignore-doesnt-apply-inside-the-vault) | Clone | The `.gitignore` doesn't apply to the vault |
| [E19](#e19-api_server_host0000-and-a-shared-key) | API | Leftover configuration and exposed key |
| [E20](#e20-sudo-tailscale-command-not-found) | Tailscale | `sudo: tailscale: command not found` |
| [E21](#e21-using-tailscale-from-another-machine) | Tailscale | Running `tailscale serve` on another machine |
| [E22](#e22-workspace-doesnt-ask-you-to-log-in) | Workspace | The interface doesn't ask for a password |
| [E23](#e23-authentication-error-in-the-chat) | Workspace | `Authentication error — check your API key in Settings` |
| [E24](#e24-update-notice-in-workspace) | Workspace | Notice about available updates |

---

## Errors found during the installation

### E1. hermes is not in the sudoers file

```
[sudo] password for hermes:
hermes is not in the sudoers file.
This incident has been reported to the administrator.
```

**When:** running `sudo loginctl enable-linger hermes`.

**Cause:** the `hermes` user wasn't in the `sudo` group. The "This incident has been reported" notice only ends up in a log inside the container itself.

**Fix:** as `root` (type `exit` to go back to it):

```bash
loginctl enable-linger hermes
```

```bash
usermod -aG sudo hermes
```

Go back with `su - hermes` and check with `groups` that `sudo` is listed.

### E2. I forgot the hermes password

**Fix:** as `root` it can be changed without the old one:

```bash
passwd hermes
```

If the `root` password is unknown too: Proxmox → node → **Shell** → `pct enter <ID>`, which gets you in as `root` without a password.

### E3. A command prints nothing

**When:** after `chmod +x ~/sync-vault.sh`.

**Cause:** not an error. In Linux, most commands only print something when they fail.

**Check:** `ls -l ~/sync-vault.sh` should start with `-rwxr-xr-x`.

### E4. Ctrl+W closes the Proxmox console

**When:** trying to search for text inside nano in the web console.

**Cause:** Ctrl+W is the browser shortcut to close the tab, and the browser catches it before nano does.

**Fix:**

- In nano, search with **F6** instead of Ctrl+W.
- Better yet, edit without opening nano when possible, for example with `sed`.
- If nano closed abruptly, it may have left an emergency copy (`.env.save`): delete it with `rm -f .env.save`.

Ctrl+O (save) and Ctrl+X (exit) do work in the browser.

### E5. The EOF block doesn't work

**When:** pasting this block to create `~/.ssh/config`:

```bash
cat >> ~/.ssh/config << 'EOF'
Host github-vault
  ...
EOF
```

**Cause:** everything was pasted on a single line. That block needs `EOF` alone on its own line, and the SSH configuration file needs one option per line.

**Fix:** create the file with `nano` and paste the content keeping the line breaks. If the file ended up broken, check it with `cat ~/.ssh/config` and rewrite it.

### E6. Key is invalid when pasting the key into GitHub

```
Key is invalid. You must supply a key in OpenSSH public key format
```

**Cause:** the key was copied from the Proxmox **noVNC** console, which handles the clipboard poorly: the text ends up truncated, split across lines or with odd characters.

**Fix:**

1. Open the **xterm.js** console (dropdown next to **Console**).
2. Run `cat ~/.ssh/vault_key.pub` and copy the whole line, from `ssh-ed25519` to `hermes-lxc`.
3. If in doubt, paste it into a text editor first and check that it's a single line.

If the **private** key is ever pasted anywhere, generate a new pair.

### E7. SHA256 shows up instead of the key

```
SHA256:xxxxxxxxxxxxxxxx...
```

**When:** running `ssh-keygen -l -f ~/.ssh/vault_key.pub`.

**Cause:** that's the key's **fingerprint**, a summary used to compare keys. It confirms the key is valid, but it can't be pasted into GitHub.

**Fix:** use `cat ~/.ssh/vault_key.pub`. After adding the key, GitHub shows that same fingerprint in the Deploy keys list, which confirms it's the right one.

### E8. The authenticity of host github.com can't be established

```
Cloning into '/home/hermes/vault'...
The authenticity of host 'github.com (...)' can't be established.
ED25519 key fingerprint is SHA256:....
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

**Cause:** it's the container's first connection to GitHub. SSH asks you to confirm the server is the real one.

**Fix:** compare the fingerprint with the official ED25519 fingerprint published by GitHub and, if it matches, type `yes`. It's stored in `~/.ssh/known_hosts` and you won't be asked again. Doing this once by hand matters: the automatic script can't answer that question.

If the clone command was pasted together with others, the following ones didn't run while the terminal waited for the answer: run them again.

### E9. Repository not found when cloning in the container

```
Warning: Permanently added 'github.com' (ED25519) to the list of known hosts.
ERROR: Repository not found.
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
```

**Cause:** the clone command still had the placeholder names (`TU-USUARIO/obsidian-vault`) instead of the real user and repository. The first line shows the connection to GitHub did work.

**Fix:** get the exact names from the key itself:

```bash
ssh -T github-vault
```

```
Hi <github-user>/<vault-repo>! You've successfully authenticated, but GitHub does not provide shell access.
```

Use exactly that user and repository, matching upper and lower case:

```bash
git clone github-vault:<github-user>/<vault-repo>.git ~/vault
```

Another safe way: on GitHub, **Code → SSH** button, copy the URL and replace `git@github.com:` with `github-vault:`.

### E10. Repository name or vault name

**Question:** does the clone take the name given to the vault in Obsidian?

**Answer:** no. They're three independent names:

| Name | What it is | Where it's used |
| --- | --- | --- |
| `<vault-repo>` | Repository on GitHub | Git commands |
| `<vault-name>` | Vault folder in Obsidian | Path Hermes uses |
| `~/vault` | Folder of the copy in the container | Sync script |

If you rename the folder in the container, avoid spaces: they complicate commands and scripts.

### E11. The notes don't show up on GitHub

**Question:** is it because of the 5-minute interval?

**Cause:** no. If they still don't show up after forcing **Git: Commit-and-sync**, the folder wasn't linked to the repository, or the commits hadn't been pushed (commit and push are separate steps). In this case, the root cause turned out to be the remote URL ([E14](#e14-repository-not-found-from-obsidian)).

**Diagnosis:** watch Obsidian's notification when running **Git: Commit-and-sync**, or run `git status` in Git Bash:

| Message | Meaning |
| --- | --- |
| `Can't find a valid git repository` | The folder isn't a repository: follow [part 2](02-vault-and-github.md#26-turn-the-folder-into-a-repository) |
| `Your branch is ahead of 'origin/main'` | There are unpushed commits: `git push -u origin main` |
| `No changes to commit` | See [E13](#e13-no-changes-to-commit) |

### E12. Select or create a new remote

```
Select or create a new remote by typing its name and selecting it
  ...
  origin
```

**When:** the first time you sync from Obsidian.

**Cause:** not an error. The local branch has no upstream configured yet.

**Fix:** choose `origin`. If it then asks for a branch, choose or type `main`.

### E13. No changes to commit

**When:** syncing after choosing `origin`.

**Cause:** not an error. The notes are already saved in a local commit; they just haven't been pushed.

**Fix:** **Ctrl+P → Git: Push**, or in Git Bash `git push -u origin main`.

### E14. Repository not found from Obsidian

```
remote: Repository not found.
fatal: repository 'https://github.com/TU-USUARIO/obsidian-vault.git/' not found
```

**When:** pushing from Obsidian, after signing in to GitHub.

**Cause:** the PC's `origin` remote had been created with the guide's placeholder URL. Signing in worked; the URL didn't.

**Fix:** in Git Bash, at the repository root:

```bash
git remote set-url origin https://github.com/<github-user>/<vault-repo>.git
```

```bash
git remote -v
```

Then merge with the GitHub README and push ([E15](#e15-push-rejected-because-of-unrelated-histories)).

### E15. Push rejected because of unrelated histories

Typical messages when pushing without merging the histories first:

```
! [rejected]        main -> main (fetch first)
fatal: refusing to merge unrelated histories
```

**Cause:** the GitHub repository was created with a README and the local folder had the notes. They're two histories that had never been joined.

**Fix:**

```bash
git pull origin main --allow-unrelated-histories --no-rebase
```

```bash
git push -u origin main
```

If an editor opens asking for a merge message, type `:wq` and Enter. In this installation, these two commands were run right after fixing the remote ([E14](#e14-repository-not-found-from-obsidian)), so the rejection was avoided and the repository was updated.

### E16. ls ~/vault shows nothing

**Cause:** the `~/vault` folder existed but was empty, created by the failed clone attempt ([E9](#e9-repository-not-found-when-cloning-in-the-container)).

**Diagnosis:**

```bash
ls -la ~/vault
```

| Result | Fix |
| --- | --- |
| Only `.` and `..` | `cd`, `rm -rf ~/vault` and clone again |
| `.git` shows up | `cd ~/vault` and `git pull origin main` |

### E17. The repo contains a subfolder and desktop.ini

```
<vault-name>  desktop.ini
```

**When:** listing `~/vault` after the clone.

**Cause:** the repository was initialized in the folder that **contains** the vault, not inside the vault. `desktop.ini` is a system file Windows creates in some folders.

**Fix:**

- No restructuring needed: the vault path in the container becomes `~/vault/<vault-name>`, and that's the one Hermes gets. The sync script works on the whole repository, so it doesn't change.
- Remove `desktop.ini` from the repository without deleting it from the PC, from Git Bash at the root:

```bash
echo "desktop.ini" >> .gitignore
```

```bash
git rm --cached desktop.ini
```

```bash
git commit -m "Ignore desktop.ini"
```

```bash
git push
```

If you don't know which folder is the root, `git rev-parse --show-toplevel` prints it. Remember that anything saved in that root folder is also pushed to GitHub.

### E18. The .gitignore doesn't apply inside the vault

**When:** spotted while reviewing the setup, after [E17](#e17-the-repo-contains-a-subfolder-and-desktopini).

**Cause:** a pattern such as `.obsidian/workspace.json` in the root `.gitignore` only matches that exact path from the root. Since the vault is in a subfolder, the real file is `<vault-name>/.obsidian/workspace.json` and it wasn't excluded.

**Fix:** start the patterns with `**/`, which means "in any subfolder":

```
**/.obsidian/workspace.json
**/.obsidian/workspace-mobile.json
**/.obsidian/cache/
**/.trash/
.DS_Store
desktop.ini
```

If `workspace.json` had already been pushed, remove it with `git rm --cached "<vault-name>/.obsidian/workspace.json"`, then commit and push.

### E19. API_SERVER_HOST=0.0.0.0 and a shared key

```
API_SERVER_ENABLED=true
API_SERVER_HOST=0.0.0.0
API_SERVER_PORT=8642
API_SERVER_KEY=<key>
```

**Question:** do these lines come from the Obsidian and GitHub setup?

**Cause:** no. The Obsidian integration only adds `OBSIDIAN_VAULT_PATH`. These lines belong to the Hermes API server and came from an earlier test with another interface (Odysseus) that ran in Docker and needed Hermes to listen on the whole network. On top of that, the key had been pasted in a chat.

**Fix:**

1. Change `API_SERVER_HOST` to `127.0.0.1`: Workspace runs in the same container.
2. Generate a new key with `openssl rand -hex 32` and replace `API_SERVER_KEY`. That key grants full control over Hermes, terminal included, and **any key shared in a chat, screenshot or message must be replaced**.
3. Restart the gateway and check with `curl http://127.0.0.1:8642/health`.
4. Stop the other interface (`docker compose down` in its folder), which won't be able to connect anymore.

### E20. sudo: tailscale: command not found

```
sudo: tailscale: command not found
```

**When:** running `sudo tailscale serve --bg 3000` in the container.

**Cause:** Tailscale was installed on another machine on the network, but not inside the container. Each machine needs its own installation.

**Fix:** follow [part 5](05-tailscale.md): give access to `/dev/net/tun` from the Proxmox host, install Tailscale in the container and connect it with `sudo tailscale up --hostname=hermesagent`.

### E21. Using Tailscale from another machine

**Question:** can `tailscale serve` run on the other machine that already has Tailscale?

**Answer:** not like that. `tailscale serve --bg 3000` publishes port 3000 **on the machine where it runs**, where there's no interface. The container's address could be published from the other machine, but Workspace would have to listen on the whole local network, the hop between the two machines would be unencrypted, and access would depend on that machine being on. That's why Tailscale was installed in the container.

### E22. Workspace doesn't ask you to log in

**When:** opening the HTTPS address for the first time.

**Cause:** the Workspace systemd service wasn't reading the `.env` file, so it started without `HERMES_PASSWORD` (and without the API key, which caused [E23](#e23-authentication-error-in-the-chat)).

**Fix:**

1. Check that the variables exist, printing only their names:

```bash
grep -E '^(HERMES_PASSWORD|HERMES_API_TOKEN|TRUST_PROXY)=' ~/hermes-workspace/.env | cut -d= -f1
```

2. Tell the service to load the `.env`:

```bash
export EDITOR=nano
```

```bash
systemctl --user edit hermes-workspace
```

```
[Service]
EnvironmentFile=/home/hermes/hermes-workspace/.env
```

3. Restart and test in a **private/incognito window**:

```bash
systemctl --user restart hermes-workspace
```

Until it's fixed the risk is low (the address only works on the Tailscale network), but if the network is shared with other people, take the publication down with `sudo tailscale serve reset`.

### E23. Authentication error in the chat

```
⚠ Authentication error — check your API key in Settings
```

**When:** messaging Hermes from Workspace.

**Cause:** `HERMES_API_TOKEN` (in Workspace's `.env`) was different from `API_SERVER_KEY` (in `~/.hermes/.env`), because the key had been changed in [E19](#e19-api_server_host0000-and-a-shared-key).

**Diagnosis:** first rule out OpenRouter: if Hermes replies on Telegram, the OpenRouter key is fine. Then check that `API_SERVER_KEY` appears only once and compare both keys without printing them:

```bash
grep -c '^API_SERVER_KEY=' ~/.hermes/.env
```

```bash
a=$(grep '^API_SERVER_KEY=' ~/.hermes/.env | cut -d= -f2-); b=$(grep '^HERMES_API_TOKEN=' ~/hermes-workspace/.env | cut -d= -f2-); [ "$a" = "$b" ] && echo EQUAL || echo DIFFERENT
```

The result was `DIFFERENT`.

**Fix:** copy the key automatically, without going through the clipboard:

```bash
key=$(grep '^API_SERVER_KEY=' ~/.hermes/.env | cut -d= -f2-); sed -i "s|^HERMES_API_TOKEN=.*|HERMES_API_TOKEN=$key|" ~/hermes-workspace/.env
```

Run the comparison again (it should say `EQUAL`) and restart:

```bash
systemctl --user restart hermes-workspace
```

If the error persists, check **Settings → Connection** in Workspace: a token saved there takes precedence over the `.env`. It must match `API_SERVER_KEY` or be empty.

If the comparison still says `DIFFERENT` after the `sed`, the `HERMES_API_TOKEN=` line probably didn't exist (or was commented out with `#`): add it with nano and repeat.

### E24. Update notice in Workspace

**When:** opening the interface for the first time.

**Decision:** don't update from the interface until everything works, so problems don't get mixed up, and do it afterwards from the terminal, where errors are visible and you know what was updated. Procedure in [maintenance](09-maintenance.md#update-hermes). Updates don't affect the vault, the sync or Hermes's memory.

---

## Other possible errors

These didn't happen in this installation, but they're the most likely ones in a setup like this.

| Symptom | Cause | Fix |
| --- | --- | --- |
| `Permission denied (publickey)` | The key on GitHub doesn't match the container's | Check that the deploy key is on that repository and is the `hermes` one |
| `Could not resolve hostname github-vault` | `~/.ssh/config` was created wrong | Check it with `cat ~/.ssh/config` and redo it with nano |
| Clone works but push fails with `denied` | Deploy key without write access | Delete it and add it again with **Allow write access** checked |
| `Failed to connect to bus` with `systemctl --user` | Session opened with `su` without linger | `loginctl enable-linger hermes` as root, log out and back in |
| `ls -l /dev/net/tun`: No such file or directory | Missing lines in `/etc/pve/lxc/<ID>.conf` | Add them and `pct reboot <ID>` |
| `pnpm build` ends with `Killed` | Not enough memory | More RAM or swap in Proxmox |
| Sessions, skills or memory say "Not Available" | The Hermes dashboard isn't running | `systemctl --user status hermes-dashboard` and check the `ExecStart` path |
| `Could not reach Hermes gateway` | Gateway stopped or missing `API_SERVER_ENABLED=true` | Restart the gateway and try `curl http://127.0.0.1:8642/health` |
| Login bounces back to the login screen | Stale cookies | Clear the site's cookies and try again |
| `tailscale serve` throws a certificate error | HTTPS not enabled in Tailscale | Enable **HTTPS Certificates** under DNS |
| A note shows `<<<<<<<` and `>>>>>>>` | The same note was edited on the PC and in the container within the same interval | Pick the right version, remove the markers and sync |

## Useful logs

| Service | Command |
| --- | --- |
| Vault sync | `journalctl --user -u vault-sync.service -n 20` |
| Hermes dashboard | `journalctl --user -u hermes-dashboard -n 40` |
| Workspace | `journalctl --user -u hermes-workspace -f` (Ctrl+C to exit) |
| Overall status | `curl http://127.0.0.1:9119/api/status` |

Before sharing any log, make sure no key appears in it; if one does, replace it with `XXXX`.

[← Previous: Hermes Workspace](06-hermes-workspace.md) · [Index](../../README.md) · [Next: Design decisions →](08-design-decisions.md)

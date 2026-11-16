# 2. Obsidian vault and GitHub

🌐 **English** · [Español](../es/02-vault-y-github.md)

[← Previous: Prepare the LXC](01-prepare-lxc.md) · [Index](../../README.md) · [Next: Sync in the LXC →](03-lxc-sync.md)

This part creates the vault on the PC, pushes it to a private GitHub repository and sets up the plugin that syncs it automatically. When you're done, the notes should be visible on GitHub.

## How the sync works

GitHub acts as the **central point**. It doesn't "send" anything to anyone: each side has a full copy of the vault and, every few minutes, pulls new changes and pushes its own.

| Side | Vault copy | What syncs it |
| --- | --- | --- |
| PC | Folder opened by Obsidian | Obsidian Git plugin |
| GitHub | Private repository | — (always available) |
| Container | `~/vault` | Script with a systemd timer |

Advantages: the PC can be off while Hermes works, and every change is kept in the history (you can review and undo it). Drawback: it isn't instant; a change can take about 10 minutes to reach the other side.

## 2.1 Install Obsidian and Git

1. Install **Obsidian** from obsidian.md.
2. Install **Git for Windows** from git-scm.com with the default options. It includes **Git Bash** (the terminal used in this part) and the credential manager that opens the browser to sign in to GitHub.

## 2.2 Create the vault

A vault is just a folder full of `.md` files.

1. Create a dedicated folder on the PC. It will be the **repository root**: don't store anything but the vault in it, because everything inside gets pushed to GitHub.
2. In Obsidian, choose **Create new vault**, give it a name (`<vault-name>`) and save it inside that folder.
3. Write a test note.

Resulting structure:

```
dedicated-folder/          ← repository root
├── .gitignore
├── README.md
└── <vault-name>/          ← the vault Obsidian opens
    ├── .obsidian/         ← Obsidian settings
    └── (.md notes)
```

> **Note:** in this installation the vault ended up inside a subfolder of the repository. It works perfectly well, but it means two things: the vault path in the container is `~/vault/<vault-name>`, and the `.gitignore` patterns must start with `**/` (see [E17](07-troubleshooting.md#e17-the-repo-contains-a-subfolder-and-desktopini) and [E18](07-troubleshooting.md#e18-the-gitignore-doesnt-apply-inside-the-vault)).

## 2.3 Create the repository on GitHub

1. On GitHub, click **New repository**.
2. Name: `<vault-repo>`.
3. Select **Private** (private repositories are free).
4. Check **Add a README file**.
5. Click **Create repository**.

## 2.4 Open Git Bash at the root

1. In Windows Explorer, go into the dedicated folder (the one that contains the vault).
2. Right click on an empty area → **Open Git Bash here** (on Windows 11, click **Show more options** first).
3. Check with `ls` that the vault folder shows up.

## 2.5 Create the .gitignore

It keeps out files that change constantly and would only cause conflicts. The patterns start with `**/` so they apply inside the vault subfolder:

```bash
printf '**/.obsidian/workspace.json\n**/.obsidian/workspace-mobile.json\n**/.obsidian/cache/\n**/.trash/\n.DS_Store\ndesktop.ini\n' > .gitignore
```

`desktop.ini` is a system file Windows creates in some folders; it's useless to both Obsidian and Hermes. The full file is in [`config/vault.gitignore.example`](../../config/vault.gitignore.example).

## 2.6 Turn the folder into a repository

Run them one by one, with your name and email:

```bash
git init
```

```bash
git config user.name "Your name"
```

```bash
git config user.email "you@example.com"
```

```bash
git add .
```

```bash
git commit -m "Initial vault from PC"
```

```bash
git branch -M main
```

```bash
git remote add origin https://github.com/<github-user>/<vault-repo>.git
```

Check the remote URL. Two lines with your real user and repo should appear:

```bash
git remote -v
```

> **Common mistake:** if a placeholder URL shows up (such as `TU-USUARIO/obsidian-vault`), the push will fail with `Repository not found`. Fix it with `git remote set-url origin https://github.com/<github-user>/<vault-repo>.git` (see [E14](07-troubleshooting.md#e14-repository-not-found-from-obsidian)).

## 2.7 Merge with the README and push

The GitHub repository already has a README and the local folder has the notes: they're two separate histories that must be merged before pushing.

```bash
git pull origin main --allow-unrelated-histories --no-rebase
```

If an editor opens asking for a merge message, type `:wq` and press Enter.

```bash
git push -u origin main
```

The first time, Windows opens the browser to sign in to GitHub. The `-u` links the branch to GitHub permanently.

## 2.8 Check on GitHub

Open the repository, **Code** tab. You should see the vault folder, `.gitignore` and `README.md`. The top bar shows the latest commit, and the **Commits** link opens the history.

If an ignored file was already pushed earlier (for example, `desktop.ini`), remove it from the repository without deleting it from the PC:

```bash
git rm --cached desktop.ini
```

```bash
git commit -m "Ignore desktop.ini"
```

```bash
git push
```

## 2.9 Install the Obsidian Git plugin

1. In Obsidian: **Settings → Community plugins** (turn off restricted mode if it's the first time).
2. **Browse**, search for **Git** (author: Vinzent03), install and enable it.

## 2.10 Configure the plugin

In the plugin settings, **Automatic** section:

| Setting | Value | Reason |
| --- | --- | --- |
| Use separate commit and push intervals | Off | A single interval commits and pushes together |
| Auto commit-and-sync interval (minutes) | `5` | With `0` (the default) changes are never pushed automatically |
| Auto commit-and-sync after stopping file edits | On | Waits until you stop typing |
| Start the automatic commit-and-sync timer from the latest commit | Off | Adds nothing here |
| Auto push interval (minutes) | `0` (greyed out) | Only used with separate intervals |
| Auto pull interval (minutes) | `5` | Brings in the changes Hermes makes |
| Auto commit-and-sync only staged files | Off | If on, normal changes are ignored |
| Specify custom commit message on auto commit-and-sync | Off | If on, it asks for a message every 5 minutes |
| Commit message on auto commit-and-sync | `PC: {{date}}` | Tells your changes apart from Hermes's in the history |

Go back to the plugin menu with the **<** arrow and also enable:

- **Pull on startup**: when Obsidian opens, it pulls whatever Hermes did while it was closed.
- **Pull on commit-and-sync**: pulls before pushing, which avoids most conflicts.

## 2.11 First sync from Obsidian

Press **Ctrl+P → Git: Commit-and-sync**.

- If the **"Select or create a new remote by typing its name and selecting it"** picker shows up, choose `origin` and, if it asks for a branch, `main`. This only happens the first time.
- **"No changes to commit"** isn't an error: the notes are already in a local commit. Use **Ctrl+P → Git: Push** to send them.

Useful palette commands:

| Command | What it does |
| --- | --- |
| Git: Commit-and-sync | Commits, pulls and pushes |
| Git: Pull | Only pulls (for example, Hermes's changes) |
| Git: Push | Only pushes pending commits |

## Check

Create a note, wait a few minutes without typing and check GitHub. The latest commit should read `PC: <date>`.

[← Previous: Prepare the LXC](01-prepare-lxc.md) · [Index](../../README.md) · [Next: Sync in the LXC →](03-lxc-sync.md)

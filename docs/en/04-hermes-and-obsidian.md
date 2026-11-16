# 4. Connect Hermes to the vault

🌐 **English** · [Español](../es/04-hermes-y-obsidian.md)

[← Previous: Sync in the LXC](03-lxc-sync.md) · [Index](../../README.md) · [Next: Tailscale in the LXC →](05-tailscale.md)

This part installs Hermes Agent, connects it to OpenRouter, and tells it where the vault is and how to sync it. Everything as the `hermes` user (never as `root`).

## 4.1 Install Hermes

```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
```

The installer sets up Python and the dependencies without needing sudo. When it finishes, log out and back in (`exit` and `su - hermes`) so the command is recognized:

```bash
hermes --version
```

## 4.2 Configure OpenRouter

```bash
hermes setup
```

1. Choose **OpenRouter** as the provider.
2. Paste your OpenRouter API key.
3. Choose a model with **at least 64K tokens of context**: Hermes rejects models with smaller windows.

OpenRouter's free models (the ones ending in `:free`) have strict usage limits. For daily use, a small balance with an inexpensive model works much better. To change the model later: `hermes model`.

## 4.3 Set the vault path

The Obsidian skill ships with Hermes. It finds the vault through the `OBSIDIAN_VAULT_PATH` variable; if it isn't set, it looks in `~/Documents/Obsidian Vault`, which doesn't exist here.

```bash
nano ~/.hermes/.env
```

This file already holds the OpenRouter API key: **don't delete anything**. Add at the end:

```
OBSIDIAN_VAULT_PATH=/home/hermes/vault/<vault-name>
```

Save (**Ctrl+O**, **Enter**) and exit (**Ctrl+X**). If Hermes or its gateway were already running, restart them so they pick up the change.

## 4.4 Teach it to use the script

Open Hermes:

```bash
hermes
```

And ask it to save this in its permanent memory:

> Save this to your memory: My Obsidian vault is at /home/hermes/vault/&lt;vault-name&gt; and is part of a Git repository synced with GitHub. Before reading or searching notes, run ~/sync-vault.sh to get the latest version. After creating or editing notes, run ~/sync-vault.sh to push the changes. When you create new notes on your own, save them in the Hermes/ folder inside the vault, unless I tell you otherwise.

The path is repeated in memory because the skill doesn't confirm which vault it's using when it loads. With both the variable and the memory, both sides are covered.

The `Hermes/` folder prevents conflicts: Hermes writes in its own area and only touches your notes when you ask it to. The timer from the previous part guarantees the sync even if Hermes forgets to run the script.

## 4.5 Test

> List the notes in my Obsidian vault and summarize what the hermes-test note is about.

> Create a note in my vault called "Hermes's first note" with a summary of what you can do with my notes, and sync the changes.

A few minutes later, the `Hermes` folder with that note shows up in Obsidian (or right away with **Ctrl+P → Git: Pull**).

## 4.6 Gateway and Telegram

The gateway is the process that keeps Hermes available outside the terminal: it handles messaging (such as Telegram) and, later on, the API used by the web interface.

1. In Telegram, talk to **@BotFather**, create a bot with `/newbot` and copy the token.
2. Configure the gateway and connect Telegram:

```bash
hermes gateway setup
```

3. Install it as a service so it starts on its own:

```bash
hermes gateway install
```

With this, Hermes replies on Telegram with no terminal open, and it can send the results of its scheduled tasks there with a phone notification. Telegram, the terminal and the web interface share the same memory and skills.

## Check

- Hermes lists your notes and creates the test note.
- The note shows up in Obsidian with no manual step.
- The Telegram bot replies.

[← Previous: Sync in the LXC](03-lxc-sync.md) · [Index](../../README.md) · [Next: Tailscale in the LXC →](05-tailscale.md)

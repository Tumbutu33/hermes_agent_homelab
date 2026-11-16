# 8. Design decisions

🌐 **English** · [Español](../es/08-decisiones-de-diseno.md)

[← Previous: Troubleshooting](07-troubleshooting.md) · [Index](../../README.md) · [Next: Maintenance →](09-maintenance.md)

This document explains why each piece was chosen over its alternatives. The general rule was to **favor free, self-hosted options that expose nothing to the internet**, accepting paid services only where they bring a clear improvement.

## Where Hermes lives: an LXC container

| Option | Pros | Cons |
| --- | --- | --- |
| **LXC container** (chosen) | Very lightweight, boots in seconds, low RAM usage | Needs tweaks for some devices (Tailscale) |
| Virtual machine | Full isolation, everything works without tweaks | Heavier on RAM and disk |
| Cloud VPS | No hardware of your own | Monthly cost, data outside the home |

Hermes doesn't run models locally (it uses them through an API), so it needs neither a GPU nor many resources. A container with 2 cores and 4 GB of RAM is enough, including building the interface.

## Models: OpenRouter

| Option | Pros | Cons |
| --- | --- | --- |
| **OpenRouter** (chosen) | Hundreds of models with one key, pay per use, free models for testing | Free models have strict limits |
| Local models | Full privacy, no per-use cost | Needs a powerful GPU |
| Nous Portal (subscription) | Models, search, images and voice for a single fee | Fixed monthly cost |

Hermes requires models with at least 64K tokens of context, and it supports fallback providers in case the main model fails.

## Vault sync: GitHub

| Option | Speed | History | Cost | Availability |
| --- | --- | --- | --- | --- |
| **GitHub (private repo)** (chosen) | Minutes | Full, with authorship | Free | Always online |
| Syncthing | Almost instant | No | Free | Both devices must be on at the same time (or the container 24/7) |
| Obsidian Sync | Instant | Limited | Paid | Always online, but hard to use from headless Linux |
| Self-hosted Gitea / Forgejo | Minutes | Full | Free | Depends on the home server |

For an agent that **edits notes autonomously**, history is the most valuable feature: every Hermes change is recorded with its author ("Hermes: date") and can be undone. GitHub also works as an off-site backup. If privacy were the priority, Gitea or Forgejo in another container offer the same without leaving the house.

## Container access to the repository: a deploy key

| Option | Blast radius if leaked |
| --- | --- |
| **Deploy key** (chosen) | That repository only |
| Account SSH key | Every repository on the account |
| Personal access token | Depends on its scopes, usually broad |

The deploy key limits the possible damage: even if someone got the container's private key, they'd only have access to the vault repository.

## Hermes's own area in the vault

Hermes writes its new notes in the `Hermes/` folder and only edits personal notes when asked. Git merges changes to different files without trouble; conflicts only appear when the PC and the container edit **the same note** within the same sync interval.

## Interface: Hermes Workspace

Four options were evaluated for an interface with plenty of features, always available and without using the terminal:

| Option | What it is | Outcome |
| --- | --- | --- |
| Open WebUI | Generic OpenAI-compatible chat interface | Works with Hermes, but only offers chat |
| Odysseus | Self-hosted AI workspace with agents, email, research and documents | Ruled out (see below) |
| **Hermes Workspace** (chosen) | Interface designed specifically for Hermes | Chosen |
| Custom interface | Purpose-built on top of the Hermes API | Feasible, pending as a future project |

**Why not Odysseus.** The goal was for Odysseus to be only the interface, with Hermes using and managing all of its tools. That isn't practical: Odysseus **is an agent itself**, with its own tools, memory and internal MCP servers. When Hermes is connected through the OpenAI-compatible API, Odysseus treats it as just another model, and Hermes can't use Odysseus's email, research or documents. Forcing it would mean depending on undocumented internal APIs of a project that changes very fast. Even the community fork that integrates both keeps them as separate agents.

**Why Hermes Workspace.** It's an interface built for Hermes to be the brain: chat with tool-call rendering, memory, skills, scheduled tasks, MCP servers, files and terminal. It runs on unmodified Hermes, uses the MIT license, installs as a phone app and doesn't need Docker. The tools Odysseus had are obtained by giving them directly to Hermes through skills and MCP servers, so they work the same from the interface, Telegram or the terminal:

| Odysseus feature | Hermes-controlled equivalent |
| --- | --- |
| Chat and agents | Hermes and its subagents |
| Memory and skills | Hermes memory and skills, editable from Workspace |
| Email and calendar | Google Workspace skill bundled with Hermes |
| Notes and documents | Obsidian vault and the Workspace file editor |
| Scheduled tasks | Hermes jobs, manageable from Workspace |
| Integrations | Hermes MCP servers, manageable from Workspace |

**Custom interface.** It's also viable: an interface talks to the gateway (port 8642, OpenAI-compatible API with real-time tool events) and to the dashboard (port 9119). The API key must never live in browser code, so a small intermediate server would hold it. Hermes could even build and maintain it inside the container.

## Remote access: Tailscale inside the container

| Option | Security | Notes |
| --- | --- | --- |
| **Tailscale in the container + `tailscale serve`** (chosen) | High | HTTPS, own devices only, no open ports |
| Tailscale on another machine | Medium | The internal hop is unencrypted and depends on another machine |
| Access by IP over HTTP | Medium | Without HTTPS the PWA and clipboard are limited |
| Opening ports on the router | Low | Exposes an agent with terminal access to the internet |

HTTPS isn't only about security: browsers only allow installing the interface as a real app from a secure address.

## Services on 127.0.0.1 only

The gateway, the dashboard and Workspace listen only inside the container. Nothing on the local network can talk to Hermes directly; the only way in is the interface, with a password and HTTPS, through Tailscale.

## Notifications: Telegram as a complement

The web interface is ideal for working with Hermes, but it isn't designed to send alerts on its own. Telegram delivers the results of scheduled tasks with push notifications. Both share the same memory and skills because the same Hermes is behind them.

[← Previous: Troubleshooting](07-troubleshooting.md) · [Index](../../README.md) · [Next: Maintenance →](09-maintenance.md)

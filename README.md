# nanobot-websocket-channel

A WebSocket channel plugin for [nanobot-ai](https://github.com/HKUDS/nanobot), plus web and Telegram clients that connect through it.

## What's inside

| Directory | What it is |
|---|---|
| `nanobot_webchat/` | WebSocket channel plugin — registers as a nanobot channel via entry points |
| `client-web-flutter/` | Flutter web chat UI — connects to the agent via WebSocket |
| `client-telegram-bot/` | Telegram bot — bridges Telegram users to the agent via WebSocket |

## Why WebSocket?

Nanobot has built-in Telegram support, but the Telegram Bot API is blocked from some networks (e.g., Russian university servers). The WebSocket channel is a transport-agnostic alternative — any web app can connect to it.

## Installation

Install the webchat channel plugin into your nanobot environment:

```bash
uv add nanobot-webchat --path /path/to/nanobot-websocket-channel
```

Then enable it in your nanobot `config.json`:

```json
{
  "channels": {
    "webchat": {
      "enabled": true,
      "allow_from": ["*"]
    }
  }
}
```

The gateway will start a WebSocket server. Clients connect at `ws://<host>:<port>`.

## Protocol

```
Client → Server: {"content": "user message"}
Server → Client: {"type": "text", "content": "response", "format": "markdown"}
```

Structured response types: `text`, `choice` (buttons), `confirm` (yes/no), `composite` (text + interaction).

API key: passed as query parameter `?api_key=...` on WebSocket connect. The channel prepends `[LMS_API_KEY=<key>]` to every message so the agent can authenticate backend requests.

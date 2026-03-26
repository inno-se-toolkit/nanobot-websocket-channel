"""WebSocket client for the nanobot AI agent gateway."""

import json
from typing import Any
from urllib.parse import urlencode

import websockets


class NanobotClient:
    """Forwards messages to the nanobot agent over WebSocket."""

    def __init__(self, ws_url: str):
        self.ws_url = ws_url

    async def ask(self, message: str, api_key: str = "") -> dict[str, Any]:
        """Send a message and return the agent's structured response.

        If *api_key* is provided it is passed as a query parameter so the
        nanobot agent can use it for LMS API calls.

        Returns a dict with at least ``type`` and ``content`` fields.
        """
        url = self.ws_url
        if api_key:
            url = f"{self.ws_url}?{urlencode({'api_key': api_key})}"
        async with websockets.connect(url, close_timeout=5) as ws:
            await ws.send(json.dumps({"content": message}))
            raw = await ws.recv()
            data: dict[str, Any] = json.loads(raw)
            # Backwards compat: if no type field, wrap as text
            if "type" not in data:
                return {
                    "type": "text",
                    "content": data.get("content", ""),
                    "format": "markdown",
                }
            return data

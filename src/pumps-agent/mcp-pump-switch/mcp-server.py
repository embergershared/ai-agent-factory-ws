import os
import threading
from contextlib import asynccontextmanager
from typing import Literal, Optional

from fastapi import FastAPI
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from starlette.types import ASGIApp, Receive, Scope, Send
from starlette.responses import PlainTextResponse

from mcp.server.fastmcp import FastMCP

# =============================================================================
# Configuration
# =============================================================================
# Set this in Azure App Service -> Configuration -> Application settings
# Example: MCP_API_KEY = "super-secret-value"
MCP_API_KEY = os.getenv("MCP_API_KEY", "dev-secret")

# =============================================================================
# Shared state (prototype only; not durable across restarts / scale-out)
# =============================================================================
STATE_LOCK = threading.Lock()
STATE = {"switch": False}  # False=OFF, True=ON


def get_state() -> bool:
    with STATE_LOCK:
        return STATE["switch"]


def set_state(value: bool) -> bool:
    with STATE_LOCK:
        STATE["switch"] = value
        return STATE["switch"]


def toggle_state() -> bool:
    with STATE_LOCK:
        STATE["switch"] = not STATE["switch"]
        return STATE["switch"]


# =============================================================================
# API key middleware (protect MCP endpoint) - Pure ASGI middleware
# =============================================================================
def extract_key_from_scope(scope: Scope) -> Optional[str]:
    """Extract API key from headers or query string."""
    # Check headers
    headers = dict(scope.get("headers", []))
    key = headers.get(b"x-api-key")
    if key:
        return key.decode("utf-8")

    # Check query string
    query_string = scope.get("query_string", b"").decode("utf-8")
    for param in query_string.split("&"):
        if param.startswith("key="):
            return param[4:]
    return None


class RequireApiKeyForMcpMiddleware:
    """Pure ASGI middleware that works with streaming responses."""

    def __init__(self, app: ASGIApp):
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send):
        if scope["type"] == "http" and scope["path"].startswith("/mcp"):
            if not MCP_API_KEY:
                response = PlainTextResponse(
                    "Server not configured: MCP_API_KEY missing", status_code=500
                )
                await response(scope, receive, send)
                return

            key = extract_key_from_scope(scope)
            if key != MCP_API_KEY:
                response = PlainTextResponse(
                    "Unauthorized (invalid or missing API key)", status_code=401
                )
                await response(scope, receive, send)
                return

        await self.app(scope, receive, send)


# =============================================================================
# MCP server definition (must be defined before lifespan)
# =============================================================================
mcp = FastMCP("valve-switch-http")


@mcp.tool()
def valve_switch_get_status() -> dict:
    """Get current valve switch status."""
    on = get_state()
    return {"status": "ON" if on else "OFF", "switch": on}


@mcp.tool()
def valve_switch_toggle() -> dict:
    """Toggle valve switch state."""
    on = toggle_state()
    return {"status": "ON" if on else "OFF", "switch": on}


@mcp.tool()
def valve_switch_set(status: Literal["ON", "OFF"]) -> dict:
    """Set valve switch explicitly to ON or OFF."""
    on = set_state(status == "ON")
    return {"status": "ON" if on else "OFF", "switch": on}


# =============================================================================
# Lifespan to manage MCP session manager
# =============================================================================
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage MCP server lifecycle."""
    async with mcp.session_manager.run():
        yield


# =============================================================================
# FastAPI app (Web UI + optional REST)
# =============================================================================
app = FastAPI(title="Valve Switch (Web + MCP over HTTP)", lifespan=lifespan)
app.add_middleware(RequireApiKeyForMcpMiddleware)

static_dir = os.path.join(os.path.dirname(__file__), "static")
app.mount("/static", StaticFiles(directory=static_dir), name="static")


@app.get("/", response_class=HTMLResponse)
def index() -> str:
    return """
<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <title>Valve switch</title>
  <style>
    body { font-family: system-ui, Arial, sans-serif; background:#0b1220; color:#e6eefc; }
    .wrap { max-width: 900px; margin: 40px auto; text-align:center; }
    .card { background:#101a33; border:1px solid #223055; border-radius:16px; padding: 28px; }
    #switchImg { width: 420px; max-width: 80vw; cursor: pointer; user-select:none; }
    .status { font-size: 22px; margin-top: 16px; }
    .hint { opacity: 0.8; margin-top: 8px; }
  </style>
</head>
<body>
  <div class="wrap">
    <div class="card">
      <h1>Valve</h1>
      <img id="switchImg" src="/static/switch_off.svg" alt="switch" />
      <div class="status" id="statusText">Status: OFF</div>
      <div class="hint">Click the switch image to toggle (web UI).</div>
    </div>
  </div>

<script>
  async function refresh() {
    const r = await fetch('/api/state');
    const data = await r.json();
    const on = data.switch === true;

    const img = document.getElementById('switchImg');
    const status = document.getElementById('statusText');

    img.src = on ? '/static/switch_on.svg' : '/static/switch_off.svg';
    status.textContent = 'Status: ' + (on ? 'ON' : 'OFF');
  }

  async function toggle() {
    await fetch('/api/toggle', { method: 'POST' });
    await refresh();
  }

  document.getElementById('switchImg').addEventListener('click', toggle);

  refresh();
  setInterval(refresh, 1000);
</script>
</body>
</html>
"""


# Optional REST endpoints (not protected here; protect if you want)
@app.get("/api/state")
def api_state():
    return JSONResponse({"switch": get_state()})


@app.post("/api/toggle")
def api_toggle():
    return JSONResponse({"switch": toggle_state()})


@app.post("/api/set/{value}")
def api_set(value: Literal["on", "off"]):
    return JSONResponse({"switch": set_state(value == "on")})


# Mount MCP ASGI app - the streamable_http_app exposes /mcp endpoint internally
# So mounting at "/" makes the endpoint available at /mcp
app.mount("/", mcp.streamable_http_app())

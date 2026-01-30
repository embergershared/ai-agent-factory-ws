# Valve Switch MCP Server

## Overview

This is a sample MCP server that manages a simple valve switch with ON/OFF states. It exposes three tools via the MCP protocol: 

1. `valve_switch_get_status`: Get the current status of the valve switch.
2. `valve_switch_toggle`: Toggle the state of the valve switch.
3. `valve_switch_set`: Set the state of the valve switch to ON or OFF.

The server can be run locally for testing or deployed to Azure Web Apps for cloud hosting.
The URL to see the valve is: [Valve Switch](https://mcp-valve-switch-ezb2abd3etaugtga.swedencentral-01.azurewebsites.net/)

## Installation commands

```pwsh
python -m venv venv
venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

```
export MCP_API_KEY="dev-secret"   # Windows PowerShell: $env:MCP_API_KEY="dev-secret"
<!-- uvicorn server:app --host 127.0.0.1 --port 8010 -->
python -m uvicorn mcp-server:app --host 127.0.0.1 --port 8010
```

## Tests

```pwsh
# Sanity check (Web API calls)
## Get current switch state
curl.exe -s http://127.0.0.1:8010/api/state

## Toggle the switch
curl.exe -s -X POST http://127.0.0.1:8010/api/toggle

## Confirm
curl.exe -s http://127.0.0.1:8010/api/state


# List tools provided by the MCP server
## Step 1: Initialize and capture session ID
$body = '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"powershell","version":"0.1"}}}'

$response = curl.exe -i http://127.0.0.1:8010/mcp `
  -H "Content-Type: application/json" `
  -H "Accept: application/json, text/event-stream" `
  -H "X-API-Key: dev-secret" `
  -d $body

## Extract session ID from response
$sessionId = ($response | Select-String "mcp-session-id: (.+)").Matches.Groups[1].Value.Trim()
Write-Host "Session ID: $sessionId"

## Step 2: Send initialized notification (required!)
$body = '{"jsonrpc":"2.0","method":"notifications/initialized"}'

curl.exe -s http://127.0.0.1:8010/mcp `
  -H "Content-Type: application/json" `
  -H "Accept: application/json, text/event-stream" `
  -H "X-API-Key: dev-secret" `
  -H "mcp-session-id: $sessionId" `
  -d $body

## Step 3: Now list tools
$body = '{"jsonrpc":"2.0","id":2,"method":"tools/list"}'

curl.exe -s http://127.0.0.1:8010/mcp `
  -H "Content-Type: application/json" `
  -H "Accept: application/json, text/event-stream" `
  -H "X-API-Key: dev-secret" `
  -H "mcp-session-id: $sessionId" `
  -d $body
```

It gives the following output:

```json
event: message
data: 
{
  "jsonrpc": "2.0",
  "id": 2,
  "result": {
    "tools": [
      {
        "name": "valve_switch_get_status",
        "description": "Get current valve switch status.",
        "inputSchema": {
          "properties": {},
          "title": "valve_switch_get_statusArguments",
          "type": "object"
        }
      },
      {
        "name": "valve_switch_toggle",
        "description": "Toggle valve switch state.",
        "inputSchema": {
          "properties": {},
          "title": "valve_switch_toggleArguments",
          "type": "object"
        }
      },
      {
        "name": "valve_switch_set",
        "description": "Set valve switch explicitly to ON or OFF.",
        "inputSchema": {
          "properties": {
            "status": {
              "enum": ["ON", "OFF"],
              "title": "Status",
              "type": "string"
            }
          },
          "required": ["status"],
          "title": "valve_switch_setArguments",
          "type": "object"
        }
      }
    ]
  }
}
```

## Call your tools via MCP

Each tool call requires a valid session. Run the complete block below to initialize, notify, and call a tool in one go.

```pwsh
### Get status (complete flow)
# Initialize
$body = '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"powershell","version":"0.1"}}}'
$response = curl.exe -i http://127.0.0.1:8010/mcp -H "Content-Type: application/json" -H "Accept: application/json, text/event-stream" -H "X-API-Key: dev-secret" -d $body
$sessionId = ($response | Select-String "mcp-session-id: (.+)").Matches.Groups[1].Value.Trim()

# Send initialized notification
$body = '{"jsonrpc":"2.0","method":"notifications/initialized"}'
curl.exe -s http://127.0.0.1:8010/mcp -H "Content-Type: application/json" -H "Accept: application/json, text/event-stream" -H "X-API-Key: dev-secret" -H "mcp-session-id: $sessionId" -d $body

# Call valve_switch_get_status
$body = '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"valve_switch_get_status","arguments":{}}}'
curl.exe -s http://127.0.0.1:8010/mcp -H "Content-Type: application/json" -H "Accept: application/json, text/event-stream" -H "X-API-Key: dev-secret" -H "mcp-session-id: $sessionId" -d $body
```

```pwsh
### Toggle (complete flow)
# Initialize
$body = '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"powershell","version":"0.1"}}}'
$response = curl.exe -i http://127.0.0.1:8010/mcp -H "Content-Type: application/json" -H "Accept: application/json, text/event-stream" -H "X-API-Key: dev-secret" -d $body
$sessionId = ($response | Select-String "mcp-session-id: (.+)").Matches.Groups[1].Value.Trim()

# Send initialized notification
$body = '{"jsonrpc":"2.0","method":"notifications/initialized"}'
curl.exe -s http://127.0.0.1:8010/mcp -H "Content-Type: application/json" -H "Accept: application/json, text/event-stream" -H "X-API-Key: dev-secret" -H "mcp-session-id: $sessionId" -d $body

# Call valve_switch_toggle
$body = '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"valve_switch_toggle","arguments":{}}}'
curl.exe -s http://127.0.0.1:8010/mcp -H "Content-Type: application/json" -H "Accept: application/json, text/event-stream" -H "X-API-Key: dev-secret" -H "mcp-session-id: $sessionId" -d $body
```

```pwsh
### Set explicitly (ON) (complete flow)
# Initialize
$body = '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"powershell","version":"0.1"}}}'
$response = curl.exe -i http://127.0.0.1:8010/mcp -H "Content-Type: application/json" -H "Accept: application/json, text/event-stream" -H "X-API-Key: dev-secret" -d $body
$sessionId = ($response | Select-String "mcp-session-id: (.+)").Matches.Groups[1].Value.Trim()

# Send initialized notification
$body = '{"jsonrpc":"2.0","method":"notifications/initialized"}'
curl.exe -s http://127.0.0.1:8010/mcp -H "Content-Type: application/json" -H "Accept: application/json, text/event-stream" -H "X-API-Key: dev-secret" -H "mcp-session-id: $sessionId" -d $body

# Call valve_switch_set with ON
$body = '{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"valve_switch_set","arguments":{"status":"ON"}}}'
curl.exe -s http://127.0.0.1:8010/mcp -H "Content-Type: application/json" -H "Accept: application/json, text/event-stream" -H "X-API-Key: dev-secret" -H "mcp-session-id: $sessionId" -d $body
```

```pwsh
### Set explicitly (OFF) (complete flow)
# Initialize
$body = '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"powershell","version":"0.1"}}}'
$response = curl.exe -i http://127.0.0.1:8010/mcp -H "Content-Type: application/json" -H "Accept: application/json, text/event-stream" -H "X-API-Key: dev-secret" -d $body
$sessionId = ($response | Select-String "mcp-session-id: (.+)").Matches.Groups[1].Value.Trim()

# Send initialized notification
$body = '{"jsonrpc":"2.0","method":"notifications/initialized"}'
curl.exe -s http://127.0.0.1:8010/mcp -H "Content-Type: application/json" -H "Accept: application/json, text/event-stream" -H "X-API-Key: dev-secret" -H "mcp-session-id: $sessionId" -d $body

# Call valve_switch_set with OFF
$body = '{"jsonrpc":"2.0","id":6,"method":"tools/call","params":{"name":"valve_switch_set","arguments":{"status":"OFF"}}}'
curl.exe -s http://127.0.0.1:8010/mcp -H "Content-Type: application/json" -H "Accept: application/json, text/event-stream" -H "X-API-Key: dev-secret" -H "mcp-session-id: $sessionId" -d $body
```

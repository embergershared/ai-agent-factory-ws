#!/bin/bash
# Azure Web App startup script for the MCP server
# This script is executed when the container starts

# Start the uvicorn server
# Azure Web App expects the app to listen on port 8000 by default (configurable via WEBSITES_PORT)
python -m uvicorn mcp-server:app --host 0.0.0.0 --port 8000

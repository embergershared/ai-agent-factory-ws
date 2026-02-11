# ─────────────────────────────────────────────────────────────────────────────
# Dockerfile – MCP Pump Switch Server
# ─────────────────────────────────────────────────────────────────────────────
FROM python:3.11-slim

WORKDIR /app

# Install dependencies first (layer caching)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code and static assets
COPY mcp-server.py .
COPY tools.json .
COPY startup.sh .
COPY static/ ./static/

# Make startup script executable
RUN chmod +x startup.sh

# Expose the port uvicorn listens on
EXPOSE 8000

# Start the server
CMD ["python", "-m", "uvicorn", "mcp-server:app", "--host", "0.0.0.0", "--port", "8000"]

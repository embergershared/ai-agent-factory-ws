# Commands for zava-agents

## Commands

```pwsh
cd .\src\zava-agents\
.\venv\Scripts\activate.ps1

# Launch starter app
uvicorn chat_app_1_starter:app --host 0.0.0.0 --port 8000

# Launch Single agent
uvicorn chat_app_2_single_agent:app --host 0.0.0.0 --port 8000

# Update multi-agent image
.\zava-shopping_bnp-to-acr.ps1

# Launch multi-agent locally
uvicorn chat_app_3_multiAgent:app --host 0.0.0.0 --port 8000

# Launch A2A agent
python .\a2a\main.py

# Launch Red team script
python app/agents/redTeamingAgent_initializer.py
```

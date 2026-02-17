# Zava Multi-Agent Demo Script

## Steps

- Launch browser and go to: [Zava shopping](https://aca-app-zava-shopping-multi.livelymushroom-0d14d900.swedencentral.azurecontainerapps.io/)

- Explain the interface

- Launch the app logging stream:
  - [aca-app-zava-shopping-multi Logstream](https://portal.azure.com/#@MngEnvMCAP391575.onmicrosoft.com/resource/subscriptions/4c88693f-5cc9-4f30-9d1e-d58d4221cf25/resourceGroups/rg-swc-s3-ai-msfoundry-demo-02/providers/Microsoft.App/containerApps/aca-app-zava-shopping-multi/logstream)
  - Click Maximize

- Execute these prompts:

What are the latest trends in home decor?
Can you help me find a sofa that fits my style?
Do you have any blue paint in stock?
What colors of green paint do you have?
I think I’m interested in Deep Forest. How many gallons would I need to paint a medium sized bedroom?
How much of PROD0018 do you have in stock?
Let’s add two gallons to the cart, please.
Please also add one paint tray and two of your All-Purpose Wall Paint Brushes.
What items are in my cart right now?
Please apply the discount that you calculated before.
I’d like to check out now.

- Launch Foundry and show the agents and their instructions

- Launch VS Code and show the code that generated the agents

- Show handoff-service agent Monitor
- Show handoff-service agent Evaluation / Automatic evaluation
- Show cora agent Evaluation / Red team
- Show ~\src\zava-agents\app\agents\redTeamingAgent_initializer.py file
- Explain the red teaming agent and how it works
- Launch:

```pwsh
cd \src\zava-agents
.\venv\Scripts\activate.ps1 
python app/agents/redTeamingAgent_initializer.py
```

Select a run option (1-6)


## Local launch options:

# Launch Single agent

```pwsh
cd .\src\zava-agents\
.\venv\Scripts\activate.ps1

# Launch Single agent
uvicorn chat_app_2_singleAgent:app --host 0.0.0.0 --port 8000

# Launch multi-agent locally
uvicorn chat_app_3_multiAgent:app --host 0.0.0.0 --port 8000

# Launch Red team script
python app/agents/redTeamingAgent_initializer.py
```

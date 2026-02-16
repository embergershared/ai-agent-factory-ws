# Pump Switch Demo Script

## Steps

Launch:

- Foundry Home on pumps-project: [pumps-agent Home](https://ai.azure.com/nextgen/r/TIhpP1zJTzCdHtWNQiHPJQ,rg-swc-s3-ai-msfoundry-demo-02,,aisvc-res-swc-s3-ai-msfoundry-demo-02,pumps-project/home)
- [Pump switch web site](https://aca-app-mcp-pump-switch.livelymushroom-0d14d900.swedencentral.azurecontainerapps.io/) => show pump is ON

- Discover:
  - Models: Overview, then models > view leaderboard, then compare models
  - Tools: show catalog
  - Solution templates

- Build:
  - Show pumps-agents agent: playground for RAG + Tools
  - Ask these questions:
    - What is the tank capacity in gallons of a Cleaver-Brooks BB Boiler Feed System ISP model and explain the model name convention?
    - What is the oil lubrication procedure for the Torishima MHDE MHD 6510 E Boiler feed water pump?
    - What are the actions you can perform on the pump switch?
    - I will start the oil lubrication procedure, switch the pump off.
  - Wait for the pump to be turned off on the pump switch web site

  - Show the components: Instructions, tools, knowledge, Memory & Guardrails
  - Show preview of the agent
  - Show compare versions:
    - change 1 model to gpt-4.1 (the other stay gpt-5.2) and launch the side-by-side chat
    - Show responses differences
  - Show traces
  - Show monitor: Operational metrics
  - Show Open in Azure monitor: to show the monitoring in Azure of the agent
  - Show evaluators & Create new evaluation
  - Show Operate
  - Show publish & publish
  - Mention/show publish it to Teams, but explain you can’t do it because of tenant limitations

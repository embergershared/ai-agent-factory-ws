# Foundry SDK README - Emm

## Overview

This section is leveraging the Azure AI Landing Zones to create agents using the Foundry SDK.

## Prerequisites

- Setup the development environment

[Prepare your development environment](https://learn.microsoft.com/en-us/azure/ai-foundry/how-to/develop/install-cli-sdk?view=foundry&tabs=windows&pivots=programming-language-python)

- Create your Virtual Environment and install the Foundry SDK

```bash
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

## Pumps-agent building steps

> Note: We will use Python for this example, but you can choose other supported languages (C#, Java, JavaScript/TypeScript).

1. Check connectivity

```bash
python 1.check-connectivity.py
```

2. Create the pumps-agent Foundry Project

```bash
python 2.create-foundry-project.py
```


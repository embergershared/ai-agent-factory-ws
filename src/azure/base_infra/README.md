# Azure Base Infrastructure – Terraform

This Terraform configuration deploys the foundational Azure infrastructure for the AI Agent Factory project using the **azurerm** and **azapi** providers with a **modular approach**.

## Architecture

```text
Resource Group
├── Virtual Network
│   ├── snet-default           (computed /27)
│   ├── snet-aca               (computed /27)  ← Container Apps delegation
│   ├── snet-private-endpoints (computed /27)
│   └── snet-ai                (computed /27)
├── Network Security Groups (one per subnet)
├── Storage Account
├── Key Vault
├── Azure AI Search
├── Azure OpenAI  (+ model deployments)
├── Cognitive Services  (multi-service)
├── Cosmos DB  (NoSQL API)
├── Azure Container Registry
├── Container Apps Environment  (+ Log Analytics)
├── Application Insights
├── AI ML Workspace
│   ├── ML Hub   (azurerm_machine_learning_workspace)
│   └── ML Project
├── AI Services  (Cognitive Account – kind = AIServices)
└── AI Foundry Project  (azapi – Microsoft.CognitiveServices/accounts/projects)
```

Subnet CIDRs are **computed dynamically** from the VNet address space using `cidrsubnet()` — no hardcoded addresses needed.

## Providers

| Provider | Source | Version |
|---|---|---|
| `azurerm` | `hashicorp/azurerm` | `~> 4.21` |
| `azapi` | `azure/azapi` | latest |
| `random` | `hashicorp/random` | `~> 3.5` |
| `time` | `hashicorp/time` | `~> 0.11` |

## Modules

| # | Module | Path | Resources |
|---|---|---|---|
| 1 | `resource_group` | `modules/resource_group/` | `azurerm_resource_group` |
| 2 | `vnet` | `modules/vnet/` | `azurerm_virtual_network`, `azurerm_subnet` (dynamic) |
| 2b | `nsg` | `modules/nsg/` | `azurerm_network_security_group`, `azurerm_subnet_network_security_group_association` (one per subnet) |
| 3 | `storage_account` | `modules/storage_account/` | `azurerm_storage_account` |
| 4 | `key_vault` | `modules/key_vault/` | `azurerm_key_vault` |
| 5 | `ai_search` | `modules/ai_search/` | `azurerm_search_service` |
| 6 | `openai` | `modules/openai/` | `azurerm_cognitive_account` (OpenAI), `azurerm_cognitive_deployment` |
| 7 | `cognitive_services` | `modules/cognitive_services/` | `azurerm_cognitive_account` (CognitiveServices) |
| 8 | `cosmosdb` | `modules/cosmosdb/` | `azurerm_cosmosdb_account` |
| 9 | `acr` | `modules/acr/` | `azurerm_container_registry` |
| 10 | `container_apps` | `modules/container_apps/` | `azurerm_container_app_environment`, `azurerm_log_analytics_workspace` |
| 11 | *(inline)* | `main.tf` | `azurerm_application_insights` |
| 12 | `ai_ml_workspace` | `modules/ai_ml_workspace/` | `azurerm_machine_learning_workspace` (Hub + Project) |
| 13 | `ai_services` | `modules/ai_new_foundry/` | `azurerm_cognitive_account` (kind = AIServices) |
| 14 | `ai_foundry_project` | `modules/ai_foundry_project/` | `azapi_resource` (Microsoft.CognitiveServices/accounts/projects) |

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.9, < 2.0
- Azure CLI authenticated (`az login`) or Service Principal credentials
- An Azure subscription with sufficient quotas

## Quick Start

```bash
# 1. Copy and edit the variables file
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your subscription ID and preferences

# 2. Initialise
terraform init

# 3. Review the plan
terraform plan -out=tfplan

# 4. Apply
terraform apply tfplan
```

## Naming Convention

All resources follow the pattern: `<abbreviation>-<project>-<environment>-<sequence>[-<suffix>]`

Resource names with length constraints (Storage Account ≤24, Key Vault ≤24, ML Workspace ≤33) are automatically truncated via `substr()` in `locals.tf`. A random 5-character suffix is appended to globally-unique names.

| Prefix | Resource |
|---|---|
| `rg-` | Resource Group |
| `vnet-` | Virtual Network |
| `snet-` | Subnet |
| `nsg-` | Network Security Group |
| `st` | Storage Account |
| `kv-` | Key Vault |
| `srch-` | AI Search |
| `oai-` | Azure OpenAI |
| `cog-` | Cognitive Services |
| `cosmos-` | Cosmos DB |
| `acr` | Container Registry |
| `acaenv-` | Container Apps Environment |
| `log-` | Log Analytics Workspace |
| `appi-` | Application Insights |
| `mlhub-` | ML Workspace Hub |
| `mlproj-` | ML Workspace Project |
| `ais-` | AI Services (Cognitive Account) |
| `aiproj-` | AI Foundry Project |

## Subnet CIDR Computation

Subnet CIDRs are **not hardcoded**. They are dynamically computed from the VNet address space using `cidrsubnet()`:

```text
VNet address space  →  /27 slices (32 IPs each)

Subnet 0: default           → cidrsubnet(vnet, newbits, 0)
Subnet 1: aca               → cidrsubnet(vnet, newbits, 1)
Subnet 2: private-endpoints → cidrsubnet(vnet, newbits, 2)
Subnet 3: ai                → cidrsubnet(vnet, newbits, 3)
```

The `newbits` value is calculated as `27 - vnet_prefix_length`, so it works with any VNet size (e.g., /24 → newbits=3, /16 → newbits=11).

## Tags

Every resource receives these default tags (via `locals.tf`):

| Tag | Value |
|---|---|
| `Project` | `var.project_name` |
| `Environment` | `var.environment` |
| `ManagedBy` | `Terraform` |
| `Owner` | Service principal name |
| `CreatedDate` | Captured once via `time_static` (immutable across runs) |

Additional tags can be added via the `extra_tags` variable.

## Lifecycle Rules

Some resources use `lifecycle { ignore_changes }` to prevent Terraform from reverting changes made by Azure services:

| Resource | Ignored Attribute | Reason |
|---|---|---|
| Key Vault | `access_policy` | ML Studio creates access policies externally |
| Container Apps Environment | `infrastructure_resource_group_name` | Azure auto-generates the managed resource group name |

## File Structure

```text
base_infra/
├── .gitignore
├── README.md
├── terraform.tf              # Provider & backend config
├── variables.tf              # Root input variables
├── locals.tf                 # Naming, tags, subnet CIDRs, derived values
├── main.tf                   # Module orchestration (14 sections)
├── outputs.tf                # Root outputs
├── terraform.tfvars.example  # Example variable values
└── ../modules/               # Shared modules (referenced via ../modules/)
    ├── resource_group/
    ├── vnet/
    ├── nsg/
    ├── storage_account/
    ├── key_vault/
    ├── ai_search/
    ├── openai/
    ├── cognitive_services/
    ├── cosmosdb/
    ├── acr/
    ├── container_apps/
    ├── ai_ml_workspace/
    ├── ai_new_foundry/
    └── ai_foundry_project/
```

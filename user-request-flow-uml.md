# User Request Flow - UML Sequence Diagram (with Deployment Layers)

```mermaid
sequenceDiagram
    actor User as 🖥️ USER BROWSER<br/>User
    participant ChatApp as ☁️ CONTAINER APP<br/>chat_app.py
    participant SessionState as ☁️ CONTAINER APP<br/>Session State
    participant Handoff as ☁️ CONTAINER APP<br/>HandoffService
    participant LLM as 🤖 FOUNDRY<br/>Azure OpenAI<br/>(LLM)
    participant Agent as 🤖 FOUNDRY<br/>Agent Executor<br/>(Thread)
    participant Search as 🤖 FOUNDRY<br/>Azure AI Search<br/>(Knowledge)
    participant Tools as 🤖 FOUNDRY<br/>Agent Tools

    User->>ChatApp: 1. WebSocket: "Add blue sofa<br/>to my cart"
    ChatApp->>SessionState: 2. Store message<br/>in history
    
    ChatApp->>Handoff: 3. classify_intent()<br/>(message + history)
    
    Handoff->>LLM: 4. Query LLM:<br/>intent classification
    
    LLM-->>Handoff: 5. Result:<br/>{domain: "cart",<br/>agent: "cart_manager"}
    
    Handoff-->>ChatApp: 6. Routing decision
    
    ChatApp->>Agent: 7. Create Foundry thread<br/>invoke agent

    Agent->>SessionState: 8. Retrieve full<br/>conversation history
    SessionState-->>Agent: 9. History context
    
    Agent->>Search: 10. Query:<br/>"blue sofa"
    
    Search-->>Agent: 11. Results:<br/>sofa-blue-001<br/>price=$599
    
    Agent->>Tools: 12. Call tool:<br/>add_to_cart()
    
    Tools-->>Agent: 13. Success:<br/>cart_total=3
    
    Agent->>LLM: 14. Generate response<br/>(using tool results)
    
    LLM-->>Agent: 15. Response text
    
    Agent-->>ChatApp: 16. Stream response
    
    ChatApp->>SessionState: 17. Update history<br/>with response
    
    ChatApp->>User: 18. WebSocket:<br/>"✓ Added blue sofa<br/>to cart"
    
    User-->>User: 19. Display response

    Note over User,Tools: FOLLOW-UP: "What colors available?"
    
    User->>ChatApp: 20. WebSocket:<br/>"What color options?"
    
    ChatApp->>Handoff: 21. classify_intent()
    
    Handoff->>LLM: 22. Intent class
    
    LLM-->>Handoff: 23. {domain: "inventory",<br/>agent: "inventory_agent",<br/>is_domain_change: true}
    
    Handoff-->>ChatApp: 24. Switch agents
    
    ChatApp->>Agent: 25. New thread +<br/>full history
    
    Agent->>Search: 26. Query:<br/>sofa-blue-001 colors
    
    Search-->>Agent: 27. [blue, grey,<br/>beige, black]
    
    Agent->>LLM: 28. Generate response
    
    LLM-->>Agent: 29. Response
    
    Agent-->>ChatApp: 30. Stream response
    
    ChatApp->>User: 31. WebSocket:<br/>Color options
```

## System Deployment Architecture - Runtime Locations

```mermaid
graph TB
    subgraph Browser["🖥️ USER BROWSER<br/>(Client-Side)"]
        WS["WebSocket Client<br/>chat.html<br/>JavaScript"]
    end

    subgraph AppService["☁️ CONTAINER APP<br/>(App Service)<br/>Runs: FastAPI/Python"]
        CA["<b>chat_app.py</b><br/>FastAPI Orchestrator<br/>WebSocket Handler<br/>Agent Routing"]
        HS["<b>HandoffService</b><br/>Intent Classification<br/>Domain Routing<br/>Agent Selection"]
        AP["<b>AgentProcessor</b><br/>Cache Manager<br/>Thread Management<br/>Agent Invocation"]
        SC["<b>Session State</b><br/>Conversation History<br/>Cart Context<br/>Loyalty Data<br/>Image Cache"]
    end

    subgraph Foundry["🤖 AZURE AI FOUNDRY<br/>(Managed Service)<br/>Runs: Agent Runtime"]
        
        subgraph Agents["AGENTS<br/>(Deployed Prompt Agents)"]
            T1["Cora<br/>Shopping Assistant"]
            T2["Cart Manager<br/>Cart Operations"]
            T3["Inventory Agent<br/>Stock Queries"]
            T4["Interior Designer<br/>Design Recommendations"]
            T5["Customer Loyalty<br/>Discount Calc"]
        end

        subgraph Knowledge["KNOWLEDGE & TOOLS"]
            AS["Azure AI Search<br/>Product Catalog<br/>Inventory DB<br/>Design Templates"]
            CT["Tool: Cart Ops<br/>add/remove items"]
            IT["Tool: Inventory<br/>Stock check"]
            DT["Tool: Design<br/>Recommendations"]
            LT["Tool: Loyalty<br/>Calc discounts"]
        end

        subgraph Memory["MEMORY & STATE<br/>(Foundry Threads)"]
            TH["Conversation Threads<br/>Per User Session<br/>Persistent Context"]
        end

        subgraph LLM["LLM BACKEND"]
            AO["Azure OpenAI<br/>GPT-4<br/>Intent Classification<br/>Response Generation"]
        end
    end

    %% Connections
    WS -->|"1. User Message<br/>via WebSocket"| CA
    CA -->|"2. Parse &<br/>Store History"| SC
    CA -->|"3. Classify Intent"| HS
    HS -->|"4. Query LLM<br/>for Classification"| AO
    AO -->|"5. Return<br/>Agent Decision"| HS
    HS -->|"6. Routing Decision"| CA
    CA -->|"7. Create/Retrieve<br/>Processor"| AP
    AP -->|"8. Thread Access"| TH
    AP -->|"9. Invoke Agent"| Agents
    
    Agents -->|"10. Query Knowledge"| Knowledge
    Agents -->|"11. Tool Calls"| Knowledge
    Agents -->|"12. LLM for Response"| AO
    Knowledge -->|"13. Tool Results"| Agents
    
    Agents -->|"14. Access Thread"| TH
    Agents -->|"15. Stream Response"| CA
    CA -->|"16. WebSocket<br/>Response"| WS

    %% Styling
    classDef browser fill:#e1f5ff,stroke:#01579b,stroke-width:3px,color:#000
    classDef appservice fill:#f3e5f5,stroke:#4a148c,stroke-width:3px,color:#000
    classDef foundry fill:#e8f5e9,stroke:#1b5e20,stroke-width:3px,color:#000
    classDef agents fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px,color:#000
    classDef knowledge fill:#fff9c4,stroke:#f57f17,stroke-width:2px,color:#000
    classDef memory fill:#ffe0b2,stroke:#e65100,stroke-width:2px,color:#000
    classDef llm fill:#ffccbc,stroke:#d84315,stroke-width:2px,color:#000
    classDef internal fill:#4a9eff,stroke:#0047ab,stroke-width:1px,color:#fff
    
    class Browser browser
    class AppService appservice
    class Foundry foundry
    class Agents agents
    class Knowledge knowledge
    class Memory memory
    class LLM llm
    class CA,HS,AP,SC internal
```

## Example User Journey: "Add blue sofa to cart" (with Deployment Zones)

```mermaid
stateDiagram-v2
    [*] --> UserInput
    
    state Browser {
        UserInput: 🖥️ User types message
        UserDisplay: 🖥️ Browser displays<br/>response
    }
    
    state AppService {
        WebSocketReceive: ☁️ chat_app.py<br/>receives via WebSocket
        ParseHistory: ☁️ Store in<br/>Session State
        ClassifyIntent: ☁️ HandoffService<br/>builds context
        GetProcessor: ☁️ Get/create<br/>AgentProcessor
        StreamResponse: ☁️ Send response<br/>via WebSocket
    }
    
    state Foundry {
        LLMClassify: 🤖 Azure OpenAI<br/>classifies intent
        IntentResult: 🤖 Intent = "cart",<br/>Agent = "cart_manager"
        FoundryThread: 🤖 Create Foundry<br/>thread
        InvokeAgent: 🤖 Agent executes<br/>logic
        AgentLogic: 🤖 Process request
        SearchProducts: 🤖 Query AI Search<br/>"blue sofa"
        ProductResult: 🤖 Found:<br/>sofa-blue-001
        CallTool: 🤖 Execute<br/>cart tool
        ToolResult: 🤖 Success:<br/>item added
        GenerateResponse: 🤖 Call OpenAI<br/>for response
        ResponseText: 🤖 "✓ Added<br/>blue sofa..."
    }

    UserInput --> WebSocketReceive
    WebSocketReceive --> ParseHistory
    ParseHistory --> ClassifyIntent
    
    ClassifyIntent --> LLMClassify
    LLMClassify --> IntentResult
    
    IntentResult --> ClassifyIntent
    ClassifyIntent --> GetProcessor
    GetProcessor --> FoundryThread
    FoundryThread --> InvokeAgent
    
    InvokeAgent --> AgentLogic
    AgentLogic --> SearchProducts
    SearchProducts --> ProductResult
    
    ProductResult --> CallTool
    CallTool --> ToolResult
    
    ToolResult --> GenerateResponse
    GenerateResponse --> ResponseText
    
    ResponseText --> StreamResponse
    StreamResponse --> UserDisplay
    UserDisplay --> [*]
    
    note right of ParseHistory
        Session state maintained
        in Container App memory
    end note
    
    note right of FoundryThread
        Agents run in Foundry
        with their own thread
        per user session
    end note
    
    note right of GenerateResponse
        All agent reasoning happens
        in Foundry (distributed from
        App Service)
    end note
```

## Runtime Zones & Component Distribution

### Zone 1: 🖥️ User Browser (Client)
**What Runs Here**: Web UI, WebSocket Client  
**Responsibility**: Send user messages, display responses in real-time  
**Connection**: WebSocket (two-way communication)

### Zone 2: ☁️ Container App / App Service (Orchestrator)
**What Runs Here**:
- `chat_app.py` — FastAPI application handling WebSocket connections
- `HandoffService` — LLM-powered intent classifier
- `AgentProcessor` — Cache manager for agent instances
- `SessionState` — In-memory storage (cart, loyalty, conversation history)

**Responsibility**: 
- Receive user messages via WebSocket
- Maintain conversation history & session context
- Classify user intent (which agent to route to)
- Manage agent lifecycle
- Stream responses back to browser

**Key**: All orchestration logic runs here; it's the "command center"

### Zone 3: 🤖 Azure AI Foundry (Agent Runtime)
**What Runs Here**:
- **5 Agents** (Cora, Cart Manager, Inventory, Interior Designer, Customer Loyalty)
- **Azure AI Search** — Product catalog, inventory, design templates
- **Agent Tools** — Cart operations, inventory checks, loyalty calculations
- **Azure OpenAI** — LLM backend for intent classification + agent reasoning
- **Conversation Threads** — Per-user state persistence at the agent level

**Responsibility**:
- Execute agent logic (domain reasoning)
- Query knowledge bases (AI Search)
- Invoke tools (cart ops, inventory, etc.)
- Generate responses using LLM
- Maintain agent-level conversation threads

**Key**: All AI/LLM execution and agent reasoning happens here; it's the "brain"

---

## Data Flow Between Zones

```
Browser (User) 
    ↓ WebSocket (user message)
Container App (Orchestration)
    ↓ Query + Intent (LLM call)
Foundry (Agent decides which tool + generates response)
    ↓ Tool results + Response
Container App (Stream to browser)
    ↓ WebSocket (response)
Browser (Display)
```

## Deployment Zones & Runtime Execution

| Zone | Component | Runs Where | Responsibility |
|------|-----------|-----------|-----------------|
| **Browser (Client)** | WebSocket Client | User's Browser | Sends user messages, displays responses |
| **App Service** | chat_app.py | Container App (FastAPI) | Orchestrates flow, manages WebSocket, routes to agents |
| **App Service** | HandoffService | Container App (FastAPI) | Classifies intent, decides which agent |
| **App Service** | AgentProcessor | Container App (FastAPI) | Manages agent cache, thread lifecycle |
| **App Service** | Session State | Container App (FastAPI) | Maintains cart, loyalty, conversation history |
| **Foundry** | 5 Agents | Foundry Runtime | Execute domain logic, call tools, generate responses |
| **Foundry** | Azure AI Search | Foundry Data Store | Stores product catalog, inventory, templates |
| **Foundry** | Agent Tools | Foundry Functions | Cart ops, inventory checks, loyalty calc |
| **Foundry** | Threads | Foundry Memory | Per-session conversation state |
| **Foundry** | Azure OpenAI | Foundry LLM | Powers intent classification + agent reasoning |

## Key Patterns

**Distributed Execution**
- Orchestration logic (routing, caching) runs in App Service
- Agent logic (reasoning, tools) runs in Foundry
- Conversation history bridges both zones

**Stateful Sessions**
- App Service maintains cart, loyalty, image cache in memory
- Each agent invocation receives full conversation history from App Service
- Agents maintain their own threads within Foundry

**Centralized Routing**
- All user messages flow through chat_app.py
- HandoffService decides which agent to invoke
- No direct agent-to-agent communication

**Streaming & Real-Time**
- WebSocket enables live response streaming from Container App to browser
- Response generation happens in Foundry; chat_app.py streams it back

**Tool-Grounded Responses**
- Agents invoke Foundry tools (cart ops, inventory, loyalty calc)
- Tool results inform LLM response generation
- All tool execution happens in Foundry zone

---

## Architecture Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                    🖥️ USER BROWSER                              │
│              (WebSocket client in HTML/JavaScript)               │
└────────────────────────┬────────────────────────────────────────┘
                         │ WebSocket
                         │ (messages/responses)
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│            ☁️ CONTAINER APP / APP SERVICE                        │
│                  (FastAPI Running)                               │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ • chat_app.py (WebSocket handler, orchestrator)         │   │
│  │ • HandoffService (intent classification)                │   │
│  │ • AgentProcessor (agent cache & lifecycle)              │   │
│  │ • SessionState (cart, loyalty, history)                 │   │
│  └──────────────────────────────────────────────────────────┘   │
└────────────────────────┬────────────────────────────────────────┘
                         │ API Calls + Streaming
                         │ (invoke agents, stream responses)
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│          🤖 AZURE AI FOUNDRY (Managed Service)                  │
│                  (Agent Runtime)                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ AGENTS (5 total):                                        │   │
│  │ • Cora, Cart Manager, Inventory, Designer, Loyalty      │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ KNOWLEDGE:                                               │   │
│  │ • Azure AI Search (product catalog, inventory, templates)│  │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ TOOLS:                                                   │   │
│  │ • Cart Ops, Inventory Check, Loyalty Calc, etc.         │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ LLM & MEMORY:                                            │   │
│  │ • Azure OpenAI (GPT-4 for reasoning)                     │   │
│  │ • Threads (per-user conversation state)                 │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

Flow Characteristics
- ✅ **Orchestration** in App Service (fast, responsive, stateful)
- ✅ **Agent Execution** in Foundry (scalable, isolated, AI-native)
- ✅ **Shared Context** via conversation history (enables agent switching)
- ✅ **Real-Time Streaming** via WebSocket (low latency to browser)
- ✅ **Tool Integration** in Foundry (grounded responses, business logic)
- ✅ **Horizontal Scaling** (Foundry agents can scale independently)


# AI Agent Factory Architecture & Process Overview

**Last Updated:** 2026-09-17

This document consolidates architectural understanding of the Zava multi-agent shopping system, including deployment zones, data flow, agent communication patterns, and integration strategies.

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Deployment Zones](#deployment-zones)
3. [Component Architecture](#component-architecture)
4. [User Request Flow](#user-request-flow)
5. [Agent Communication Patterns](#agent-communication-patterns)
6. [A2A (Agent-to-Agent) Integration](#a2aagent-to-agent-integration)
7. [Common Integration Patterns](#common-integration-patterns)

---

## System Overview

The AI Agent Factory implements a **centralized orchestration with distributed execution** pattern:

- **Orchestration Layer:** `chat_app.py` running in Container App handles routing, session state, and conversation management
- **Agent Execution Layer:** Five prompt agents (Cora, Cart Manager, Inventory, Interior Designer, Customer Loyalty) run in Microsoft Foundry
- **Knowledge Layer:** Azure AI Search provides grounded responses with product catalog, inventory, and design templates
- **LLM Layer:** Azure OpenAI (GPT-4) powers intent classification and agent reasoning

### Key Technologies

| Component | Purpose | Platform |
|-----------|---------|----------|
| **chat_app.py** | WebSocket orchestrator, conversation router, state manager | Container App (Python/FastAPI) |
| **Foundry Agents** | Specialized prompt agents for domain reasoning | Microsoft Foundry |
| **Azure OpenAI** | LLM backbone for agent reasoning & intent classification | Azure AI Services |
| **Azure AI Search** | Vector/hybrid search over product knowledge base | Azure Search |
| **A2A Service** | HTTP-based agent-to-agent interoperability (separate from Foundry) | Port 8001 (src/zava-agents/a2a/) |

---

## Deployment Zones

Three distinct deployment zones execute different responsibilities:

### 1. **Browser Zone** (Client-Side)
- **Components:** WebSocket client, UI state
- **Responsibilities:** User interaction, message display, session tokens
- **Protocol:** WebSocket connection to App Service
- **Examples:**
  - User types: "Add a blue sofa to my cart"
  - Browser sends WebSocket message to chat_app.py

### 2. **Container App Zone** (Application Service)
- **Components:** 
  - `chat_app.py` WebSocket handler
  - `HandoffService` (intent classifier using Azure OpenAI)
  - `SessionState` (conversation history, context)
  - `AgentProcessor` (routes to Foundry agents)
- **Responsibilities:** 
  - Accept WebSocket connections
  - Classify user intent
  - Route to appropriate agent
  - Maintain conversation state
  - Bridge user context to Foundry
- **Key Decisions:**
  - Which agent should handle this request?
  - When to switch agents based on domain change?
  - How to preserve context across agent switches?

### 3. **Foundry Zone** (Agent Runtime)
- **Components:**
  - Cora (Greeting/Onboarding)
  - Cart Manager (Shopping cart operations)
  - Inventory Agent (Stock inquiries)
  - Interior Designer (Design consultation)
  - Customer Loyalty (Rewards & personalization)
  - Azure AI Search (Knowledge base)
  - Azure OpenAI (LLM inference)
  - Threads (Session/conversation persistence)
- **Responsibilities:**
  - Agent reasoning with LLM
  - Knowledge base queries
  - Conversation thread persistence
  - Tool invocation (if agents have tools defined)
  - Response generation grounded in knowledge

---

## Component Architecture

### System Deployment Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          BROWSER ZONE                               │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │  WebSocket Client                                            │   │
│  │  - Send user messages                                        │   │
│  │  - Receive agent responses                                   │   │
│  │  - Display chat history                                      │   │
│  └──────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────┬───────────────────────────┘
                                          │ WebSocket
                                          │ (JSON messages)
                                          ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      CONTAINER APP ZONE                              │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │  chat_app.py (FastAPI + WebSocket)                           │   │
│  │  - Accepts WebSocket connections                             │   │
│  │  - Maintains session state                                   │   │
│  │  ┌─────────────────────────────────────────────────────────┐ │   │
│  │  │ HandoffService                                          │ │   │
│  │  │ - Classifies user intent using Azure OpenAI GPT-4       │ │   │
│  │  │ - Determines which agent should handle request          │ │   │
│  │  │ - Routes to appropriate Foundry agent                   │ │   │
│  │  └─────────────────────────────────────────────────────────┘ │   │
│  │  ┌─────────────────────────────────────────────────────────┐ │   │
│  │  │ SessionState                                            │ │   │
│  │  │ - Conversation history                                  │ │   │
│  │  │ - Current agent context                                 │ │   │
│  │  │ - User preferences                                      │ │   │
│  │  └─────────────────────────────────────────────────────────┘ │   │
│  │  ┌─────────────────────────────────────────────────────────┐ │   │
│  │  │ AgentProcessor                                          │ │   │
│  │  │ - Calls Foundry agents via API                          │ │   │
│  │  │ - Manages response integration                          │ │   │
│  │  │ - Handles agent timeouts/errors                         │ │   │
│  │  └─────────────────────────────────────────────────────────┘ │   │
│  └──────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────┬───────────────────────────┘
                                          │ Azure Foundry API
                                          │ (REST + Thread messages)
                                          ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        FOUNDRY ZONE                                   │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │  Foundry Agent: Cora (Greeting)                              │   │
│  │  Foundry Agent: Cart Manager (Shopping)                      │   │
│  │  Foundry Agent: Inventory (Stock inquiry)                    │   │
│  │  Foundry Agent: Interior Designer (Consultation)             │   │
│  │  Foundry Agent: Customer Loyalty (Rewards)                   │   │
│  │                                                              │   │
│  │  Shared Resources:                                           │   │
│  │  ├─ Azure OpenAI (GPT-4)     [LLM reasoning]                │   │
│  │  ├─ Azure AI Search          [Knowledge base queries]       │   │
│  │  └─ Threads                  [Conversation persistence]     │   │
│  └──────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

### Deployment Zones Table

| Component | Zone | Responsibility | Technology |
|-----------|------|-----------------|-----------|
| **WebSocket Client** | Browser | User interaction & message display | JavaScript/HTML |
| **chat_app.py** | App Service | Connection handling, WebSocket management | FastAPI + Python |
| **HandoffService** | App Service | Intent classification & agent routing | Azure OpenAI |
| **SessionState** | App Service | Conversation history & context | In-memory or persistent store |
| **AgentProcessor** | App Service | Foundry API calls & response integration | Python async client |
| **Cora Agent** | Foundry | Greeting & onboarding conversation | Prompt Agent |
| **Cart Manager Agent** | Foundry | Shopping cart operations | Prompt Agent |
| **Inventory Agent** | Foundry | Stock & availability inquiries | Prompt Agent |
| **Interior Designer Agent** | Foundry | Design consultation & recommendations | Prompt Agent |
| **Customer Loyalty Agent** | Foundry | Rewards & personalization | Prompt Agent |
| **Azure AI Search** | Foundry | Product catalog & knowledge queries | Vector/Hybrid Search |
| **Azure OpenAI** | Foundry | LLM reasoning for all agents | GPT-4 |
| **Threads** | Foundry | Conversation persistence per session | Foundry managed |

---

## User Request Flow

### Example Journey: "Add blue sofa to cart"

```
Step 1: Browser sends message
  └─> WebSocket: { "message": "Add a blue sofa to my cart" }
         ├─ User context: { "sessionId": "xyz", "userId": "user123" }
         └─ Conversation history attached

Step 2: chat_app.py receives & classifies intent
  └─> HandoffService calls Azure OpenAI
         ├─ Input: "Add a blue sofa to my cart"
         ├─ Response: { "domain": "shopping", "intent": "add_to_cart", "entity": "blue sofa" }
         └─ Decision: Route to "Cart Manager Agent"

Step 3: chat_app.py sends to Foundry
  └─> AgentProcessor calls Foundry API
         ├─ Agent ID: "cart-manager"
         ├─ Thread ID: "thread-xyz"
         ├─ Message: "Add a blue sofa to my cart"
         └─ Context: Previous messages in thread + session context

Step 4: Foundry processes
  └─> Cart Manager Agent reasoning
         ├─ LLM interprets: "User wants to add an item to shopping cart"
         ├─ Calls Azure AI Search: "Find product matching 'blue sofa'"
         ├─ Search returns: [{ id: "prod-456", name: "Blue Sofa", price: "$799", stock: 5 }]
         ├─ LLM generates response: "I found the Blue Sofa for $799. Adding to your cart!"
         └─ Response stored in Thread

Step 5: Response flows back
  └─> chat_app.py retrieves Foundry response
         ├─ Thread message: "I found the Blue Sofa for $799. Adding to your cart!"
         ├─ Updates SessionState: cart=[{ product: "Blue Sofa", qty: 1 }]
         └─ WebSocket sends to Browser

Step 6: Browser displays
  └─> User sees: "I found the Blue Sofa for $799. Adding to your cart!"
         ├─ Cart UI updates
         └─ Ready for next message

Total Zones Crossed: Browser (step 1) → App Service (steps 2-3, 5-6) → Foundry (step 4)
```

### Multi-Turn Agent Switch Example

**Scenario:** User adds item, then asks about warranty (design consultation)

```
Message 1: "Add blue sofa to cart"
  └─> Intent: "shopping" → Cart Manager Agent ✓
      (Steps as above)

Message 2: "Can the Interior Designer tell me if this matches my bedroom?"
  └─> HandoffService classifies:
      { "domain": "design", "intent": "consultation_request" }
      ├─ Decision: Switch to Interior Designer Agent
      ├─ Why different agent? Different domain expertise
      └─ SessionState still contains: { cart, userId, conversation_history }

Message 3 (In Foundry - Interior Designer Agent):
  └─> Agent has access to:
      ├─ Conversation history (previous "Add sofa" message)
      ├─ User cart context (blue sofa details)
      ├─ Design knowledge base from Azure AI Search
      └─ Generates: "The blue sofa would work well in a modern bedroom..."
```

**Key Points:**
- Orchestrator decides when to switch agents (centralized control)
- Conversation history bridges both agents (SessionState preserved)
- Agents don't directly communicate (routing is explicit)
- Each agent is stateless; Threads maintain continuity

---

## Agent Communication Patterns

### Current Pattern: Orchestrator-Mediated (chat_app.py)

```
┌────────────┐
│   Agent A  │
│ (Cart Mgr) │
└─────┬──────┘
      │
      ├─── NOT Direct ───┐
      │                   │
      │                   ▼
      │            ┌──────────────┐
      │            │ SessionState │
      │            └──────────────┘
      │                   ▲
      │                   │
      │            ┌──────────────┐
      ├────REST──>│  chat_app.py │<────REST──┐
      │           │ (Orchestrator)│           │
      │            └──────────────┘           │
      │                   ▲                    │
      └────────────────────────────────────────┘
```

**Characteristics:**
- ✅ Centralized control and visibility
- ✅ Easy state management
- ✅ Simple routing logic
- ❌ Agents cannot directly communicate
- ❌ All traffic flows through App Service

---

## A2A (Agent-to-Agent) Integration

### What is A2A?

**A2A (Agent-to-Agent Protocol)** is an HTTP-based interoperability standard enabling agents to communicate peer-to-peer, regardless of platform or location.

### A2A in This Project

Located in: `src/zava-agents/a2a/`

**Purpose:**
- Reference implementation of A2A service
- Runs on port 8001
- Separate from main Foundry orchestration
- Enables cross-cloud agent communication

**Separate from Foundry:**
- Foundry agents ≠ A2A agents
- A2A is for *interop*, not the default communication pattern
- Used when you need agent-to-agent calls (either same project or cross-project)

### When to Use A2A

| Scenario | Use A2A? | Notes |
|----------|----------|-------|
| Agent calls another agent in same Foundry project | ✅ Yes | Add A2A Bridge Tool to calling agent |
| Agent calls external system | ✅ Yes (if REST-based) | Implement as tool or webhook |
| Foundry agents communicate via orchestrator | ❌ No | Already have centralized routing |
| Cross-cloud agent collaboration | ✅ Yes | A2A is the standard |
| Multiple Foundry projects need to interact | ✅ Yes | A2A bridges projects |

---

## Agent Communication: Native vs. A2A

### ❌ No Native Agent-to-Agent Calling

**Finding:** Foundry agents **do NOT natively call each other** within the same project.

- Agents are designed to invoke **Tools**, **Knowledge Indexes**, and **External Services**
- No built-in "call Agent X" capability
- This is by design: agents should be stateless reasoners

### ✅ A2A Bridge Tool Pattern (Recommended)

If Agent A needs to invoke Agent B, implement via **A2A Bridge Tool**:

**Step 1: Define A2A Bridge Tool in Agent A**

```json
{
  "name": "invoke_interior_designer",
  "description": "Ask the Interior Designer agent for design advice",
  "inputSchema": {
    "type": "object",
    "properties": {
      "question": {
        "type": "string",
        "description": "Design question for the Interior Designer agent"
      },
      "context": {
        "type": "string",
        "description": "Current shopping/design context"
      }
    },
    "required": ["question", "context"]
  }
}
```

**Step 2: Implement Tool Handler in Agent A (Python)**

```python
async def invoke_interior_designer(question: str, context: str) -> str:
    """
    Call Interior Designer agent via A2A protocol.
    
    This demonstrates agent-to-agent communication within the same Foundry project.
    """
    async with httpx.AsyncClient(timeout=30.0) as client:
        payload = {
            "messages": [
                {
                    "role": "user",
                    "content": f"{question}\n\nContext: {context}"
                }
            ]
        }
        
        # Call Interior Designer A2A endpoint
        response = await client.post(
            "http://interior-designer-a2a-endpoint/invoke",
            json=payload,
            headers={
                "Authorization": f"Bearer {os.getenv('FOUNDRY_API_KEY')}",
                "Content-Type": "application/json"
            }
        )
        
        result = response.json()
        return result.get("response", "No response from Interior Designer")

# Register with Foundry agent
@app.post("/tool/invoke_interior_designer")
async def handle_design_query(request: InvokeRequest):
    result = await invoke_interior_designer(
        question=request.input.get("question"),
        context=request.input.get("context")
    )
    return {"result": result}
```

**Step 3: Flow Diagram**

```
Cart Manager Agent (in Foundry)
    │
    ├─ LLM reasoning: "Need design advice for sofa placement"
    │
    ├─ Invokes Tool: "invoke_interior_designer"
    │    └─ HTTP POST to A2A endpoint
    │
    ▼
Interior Designer Agent (in Foundry)
    │
    ├─ Receives A2A request
    │
    ├─ LLM reasoning: "Analyze placement in bedroom context"
    │
    ├─ Queries Azure AI Search for design rules
    │
    ▼
Response: "Blue sofa works well with modern bedroom style..."
    │
    └─> Back to Cart Manager Agent via HTTP response
         └─> Incorporated into final response to user
```

### Key Differences

| Aspect | Orchestrator-Mediated | A2A Bridge Tool |
|--------|----------------------|-----------------|
| **Initiator** | chat_app.py | One agent's tool |
| **Protocol** | Direct Foundry API calls | HTTP (A2A standard) |
| **Visibility** | App Service sees all routing | Isolated to agents |
| **Use Case** | Domain-based routing decisions | Agent expertise needed |
| **Complexity** | Lower | Higher |
| **Scalability** | Limited by App Service | Peer-to-peer |

---

## Common Integration Patterns

### Pattern 1: Knowledge Base Query

**When:** Agent needs to ground response in facts

```
Agent Reasoning
    ↓
Tool: query_knowledge_base(query_text)
    ↓
Azure AI Search
    ├─ Vector search: Semantic similarity
    ├─ Hybrid search: Keyword + semantic
    └─ Filter by: Product category, availability, price
    ↓
Results: [Product data, pricing, inventory]
    ↓
Agent incorporates into response
```

**Example in Interior Designer:**
- User: "What sofas match a Scandinavian bedroom?"
- Tool call: `query_knowledge_base("Scandinavian sofas")`
- Search returns: [Modern Grey Sofa, Light Oak Sofa, ...]
- Agent responds: "I found these Scandinavian sofas..."

### Pattern 2: Agent-to-Agent via A2A Bridge

**When:** Current agent needs specialized expertise

```
Cart Manager Agent
    │
    ├─ Task: Determine if item matches user's style
    │
    ├─ Calls A2A Tool: invoke_interior_designer(...)
    │
    ▼
Interior Designer Agent
    │
    ├─ Expertise: Design patterns, color theory
    │
    ├─ Queries Knowledge Base: Design rules
    │
    ▼
Recommendation: "Yes, matches Scandinavian style"
    │
    └─> Back to Cart Manager as tool result
         └─> Included in response to user
```

### Pattern 3: Context Handoff with Agent Switch

**When:** Domain switches (orchestrator decision)

```
Browser: "Add blue sofa, will it match my bedroom?"
    ↓
chat_app.py classifies: Intent contains both "shopping" AND "design"
    ├─ Option A: Route only to Cart Manager, he calls Interior Designer via A2A
    ├─ Option B: Sequential: Cart Manager first, then switch to Interior Designer
    └─ Choice depends on complexity and agent capabilities
    ↓
SessionState provides context to next agent
    ├─ Conversation history
    ├─ Sofa details (already selected)
    └─ User design preferences
    ↓
Next Agent reasoning includes all context
```

### Pattern 4: External API Tool

**When:** Agent needs to call external services

```
Customer Loyalty Agent
    │
    ├─ Task: Check reward points balance
    │
    ├─ Calls Tool: get_loyalty_balance(user_id)
    │    └─ HTTP POST to external loyalty service API
    │
    ▼
External Service
    └─ Returns: { points: 2500, tier: "Gold" }
    │
    └─> Tool result incorporated into agent response
         "You have 2500 points (Gold tier)"
```

---

## Architecture Decisions & Trade-offs

### Why Orchestrator-Mediated for Primary Routing?

✅ **Pros:**
- Central visibility into all conversations
- Easy to add new routing rules
- Can implement global policies (rate limiting, audit)
- Simple state management

❌ **Cons:**
- App Service becomes bottleneck
- Agents cannot act autonomously
- Every conversation flows through orchestrator

### Why A2A for Agent-to-Agent?

✅ **Pros:**
- Agents can collaborate without App Service involvement
- Scales to peer-to-peer architecture
- Follows industry standard (works across platforms)
- Agents retain autonomy

❌ **Cons:**
- Harder to debug (multiple hops)
- Requires error handling for cascading failures
- Less visibility into agent-to-agent calls

### Recommended Hybrid Approach

```
┌─ Orchestration Layer (chat_app.py)
│  └─ Decides: Which agent handles this request?
│
├─ Agent Layer (Foundry)
│  ├─ Agent A (needs external expertise)
│  │  └─ Tool: A2A Bridge → Calls Agent B
│  │
│  ├─ Agent B (consulted as tool)
│  │  └─ Returns expertise to Agent A
│  │
│  └─ Both agents: Query Knowledge Base as needed
│
└─ Data Layer
   └─ SessionState (orchestrator owns)
   └─ Azure AI Search (all agents access)
```

**Usage:**
- **Chat_app.py decides:** High-level domain routing, agent selection
- **Agents decide:** Tactical expertise delegation via A2A tools
- **Result:** Centralized control + agent autonomy = best of both worlds

---

## Quick Reference

### File Locations

| Component | Location |
|-----------|----------|
| Orchestrator | `src/zava-agents/chat_app.py` |
| A2A Service | `src/zava-agents/a2a/` |
| Agent Prompts | `src/zava-agents/prompts/` |
| Infrastructure | `src/zava-agents/infra/` |
| App Code | `src/zava-agents/app/` |
| Utilities | `src/zava-agents/utils/` |

### Key Ports

| Service | Port | Purpose |
|---------|------|---------|
| chat_app.py | 8000 | WebSocket, main orchestrator |
| A2A Service | 8001 | Agent-to-agent HTTP endpoint |

### Decision Tree: How to Add Agent Communication

```
Do agents need to communicate?
├─ NO  → No changes needed
│
└─ YES
   ├─ Within same Foundry project?
   │  ├─ YES → Use A2A Bridge Tool pattern (see above)
   │  └─ NO  → Use A2A Bridge Tool (works cross-project too)
   │
   ├─ Should orchestrator know about it?
   │  ├─ YES → Keep using orchestrator-mediated (chat_app.py)
   │  └─ NO  → Add A2A tool to calling agent
   │
   └─ Needs to be atomic transaction?
      ├─ YES → Orchestrator handles (currently not A2A)
      └─ NO  → A2A tool is fine
```

---

## Next Steps for Implementation

1. **Add A2A Tool to Cart Manager:**
   - Define tool schema for "ask interior designer"
   - Implement HTTP client to Interior Designer's A2A endpoint
   - Test with sample design queries

2. **Add A2A Tool to Other Agents:**
   - Inventory → Cart Manager (for bundle queries)
   - Loyalty → All agents (for personalization)
   - etc.

3. **Monitor A2A Calls:**
   - Add logging to trace agent-to-agent communications
   - Track latency across agents
   - Alert on cascading failures

4. **Enhance Orchestrator:**
   - Implement smarter intent classification
   - Add multi-intent detection (e.g., "shopping + design")
   - Consider sequential agent execution for complex queries

---

## Related Documentation

- User Request Flow UML: See `user-request-flow-uml.md`
- Infrastructure Code: `src/azure/zava-shopping_infra/`
- Agent Prompts: `src/zava-agents/prompts/`
- A2A Reference Implementation: `src/zava-agents/a2a/`

---

**Questions?** Review the deployment zones diagram or check specific agent implementations in `src/zava-agents/app/`

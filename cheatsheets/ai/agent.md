# AI Agents Development: Best Practices & Cheatsheet

A comprehensive guide and cheatsheet for designing, building, and optimizing production-grade AI agents.

---

## 1. Core Architecture Principles

When building agents, favor simplicity and deterministic design over raw LLM autonomy where possible.

* **The Power of Loops:** Use simple LLM call loops (like the ReAct framework) for reasoning, but constrain them with maximum iteration limits to prevent infinite loops and runaway API costs.
* **Separation of Concerns:** Split complex tasks into a network of specialized, single-purpose agents rather than relying on one "all-knowing" agent.
* **Structured Inputs & Outputs:** Always enforce structured schemas (e.g., Pydantic objects or JSON Schema) for tool calls and final agent responses to ensure system reliability.

---

## 2. Tool Design Best Practices

Agents are only as good as the tools they can access. Design tools with the same rigor you would apply to a public API.

* **Granular Tooling:** Give agents small, atomic tools (e.g., `read_file`, `edit_line`) instead of broad, complex ones (e.g., `manage_repository`).
* **Explicit Descriptions:** The LLM relies entirely on the tool's docstring and argument descriptions. Be hyper-specific about what the tool does and when to use it.
* **Fail Gracefully:** Tools should catch exceptions and return descriptive error messages *to the LLM* so the agent can self-correct (e.g., "Error: File not found. Did you mean...").

### Tool Definition Example (Python / Pydantic)

```python
from pydantic import BaseModel, Field

class CalculateRevenueArgs(BaseModel):
    quarter: str = Field(..., description="The fiscal quarter, formatted as Q1, Q2, Q3, or Q4.")
    year: int = Field(..., description="The 4-digit calendar year (e.g., 2026).")

def calculate_revenue(args: CalculateRevenueArgs) -> str:
    """Calculates the total revenue for a specific fiscal quarter and year."""
    # Tool implementation goes here
    return "Calculated Revenue: $1.2M"
```

---

## 3. Prompt Engineering for Agents

Agent prompts require a focus on behavioral boundaries, orchestration, and systematic execution.

* **Clear Identity & Persona:** Establish who the agent is and its exact boundaries.
* **Step-by-Step Execution:** Force the agent to think before acting (e.g., "Before calling a tool, write down a 'Thought' explaining why this tool is necessary").
* **Negative Constraints:** Clearly state what the agent **cannot** or **should not** do to avoid catastrophic failures or security risks.

### System Prompt Template

```text
You are an expert Data Retrieval Agent. Your sole purpose is to fetch and aggregate data from the provided database tools.

CRITICAL RULES:
1. Only use the tools provided to you. Do not invent facts or guess parameters.
2. If the tools return an error, report the error clearly and attempt an alternative tool if applicable.
3. NEVER expose internal database IDs or raw connection strings to the user.
4. If the data cannot be found after 3 attempts, halt and inform the user.

EXECUTION PROTOCOL:
- Thought: Reason about the current state and what tool is needed next.
- Action: Call the appropriate tool with precise arguments.
- Observation: Review the output of the action.
- Repeat until the final answer is reached.
```

---

## 4. Memory and State Management

Agents require context to execute multi-step plans and handle long-running operations.

| Memory Type                   | Description                                                     | Best Use Case                                          |
|:------------------------------|:----------------------------------------------------------------|:-------------------------------------------------------|
| **Short-Term (Conversation)** | Ephemeral context tracking the current session or task loop.    | Chat history, tool execution history.                  |
| **Long-Term (Persistent)**    | Vector embeddings or database storage across multiple sessions. | User preferences, past execution successes/failures.   |
| **Entity Memory**             | Extracting and storing specific facts about subjects over time. | User profiles, project details, system configurations. |

---

## 5. Security Guardrails

Operating autonomous agents introduces significant security vectors. Implement these baselines strictly.

* **Human-in-the-Loop (HITL):** Require explicit human approval for destructive, high-risk, or financial actions (e.g., deleting files, sending emails, processing payments).
* **Sandboxed Environments:** Run code execution or file-system-altering agents inside secure, ephemeral containers (e.g., Docker, WebAssembly).
* **Principle of Least Privilege:** API keys and credentials used by agent tools must only have the absolute minimum permissions required to perform their specific task.

---

## 6. Testing & Evaluation (Evals)

Traditional unit testing is insufficient for stochastic AI agents. Use system-level evaluation frameworks.

* **Trajectory Testing:** Don't just test the final output; log and assert against the *sequence* of tool calls the agent made to ensure efficiency.
* **Deterministic Mocking:** Mock all external tool outputs to test the agent's reasoning loop in isolation from external API fluctuations.
* **Assertion-Based Evals:** Use LLM-as-a-judge frameworks to grade responses on criteria like factual correctness, tone, and adherence to negative constraints.

```bash
# Recommended tools for Agent logging, tracing, and evaluation
pip install langfuse   # Tracing and engineering metrics
pip install phoenix    # LLM observability and evaluation
pip install promptfoo  # CLI-driven LLM application evaluation
```
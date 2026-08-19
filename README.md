# Agent Auth Labs

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https.apache.org/licenses/LICENSE-2.0)
[![Google Cloud](https://img.shields.io/badge/Google%20Cloud-Enterprise%20AI%20Security-4285F4?logo=googlecloud&logoColor=white)](https://cloud.google.com)
[![ADK](https://img.shields.io/badge/Google%20ADK-Agent%20Development%20Kit-34A853)](https://github.com/google/adk-samples)

**Agent Auth Labs** is a research, enablement, and architectural reference repository for **Enterprise AI Agent Security & Identity**. It demonstrates how to architect, deploy, and govern Autonomous AI Agents with **Zero-Trust Identity** using the **Google Agent Development Kit (ADK)** on **Gemini Enterprise Agent Platform (GEAP / Agent Runtime / Discovery Engine)**.

---

## 🎯 Executive Vision: The Identity Crisis in Agentic AI

Enterprise AI agents are increasingly granted autonomous access to both shared corporate infrastructure (databases, vector stores, reasoning engines) and sensitive user-scoped resources (Google Drive, Gmail, CRM, ERP). 

### The Non-Google DIY Dilemma (Application-Level Trust)
In traditional DIY agent frameworks (LangChain, CrewAI, AutoGen on AWS/Azure/K8s), security controls are almost entirely **delegated to the application code and LLM prompts**:
- Developers rely on the agent's Python code or helper functions to voluntarily "do the right thing" — check permissions, validate scopes, sanitize output, and avoid logging credentials.
- **The Failure Mode**: LLMs are probabilistic, non-deterministic execution engines vulnerable to direct and indirect prompt injection, goal hijacking, and tool manipulation. If an attacker tricks an agent into running malicious Python code or dumping its environment, the entire security perimeter collapses because:
  1. Static API keys and long-lived Service Account JSON keys reside directly on the container filesystem or in environment variables (`.env`).
  2. End-user OAuth refresh tokens are persisted in centralized PostgreSQL/Redis "token vaults".
  3. The agent runtime has unrestricted outbound internet access, allowing immediate exfiltration of tokens and enterprise data.

### The Google Enterprise Solution: Platform-Enforced Zero-Trust
The Google stack combining **Google ADK** with **Gemini Enterprise Agent Platform (GEAP)** rejects application-level trust in favor of a **Platform-Enforced Zero-Trust Security Model**:

> **Core Axiom:** *The platform must remain 100% secure even if the Agent is fully compromised by prompt injection or if the tool code fails to do the "right thing".*

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│               WHY GOOGLE STACK DOES NOT RELY ON AGENT "DOING THE RIGHT THING"          │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ 1. Gateway Gating (Discovery Engine):                                                 │
│    User consent is validated by the platform BEFORE the agent container is invoked.   │
│    The agent cannot bypass or forge user consent.                                      │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ 2. Hardware-Rooted SPIFFE / Workload Identity (ALTS):                                 │
│    Zero static keys exist in the container. Ephemeral SVIDs / OIDC tokens are       │
│    cryptographically minted by the hypervisor metadata plane with strict audiences.    │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ 3. Ephemeral Turn-Scoped Memory Seclusion:                                             │
│    User OAuth tokens exist ONLY in in-memory turn state (temp:<AUTH_ID>) and are      │
│    automatically dropped post-turn. Never written to disk, context window, or logs.   │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ 4. Kernel-Level Perimeter Enforcement (VPC Service Controls):                         │
│    Even if an attacker executes code inside the tool to exfiltrate tokens, VPC-SC and │
│    Private Google Access drop all unauthorized outbound traffic at the network layer.  │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🏛️ Architecture & Comparative Topologies

### Google ADK + GEAP Zero-Trust Identity Pipeline

![Zero-Trust Identity Pipeline](./labs/dev/enterprise-adk-agent-auth/img/zero_trust_pipeline.png)

### Vulnerable DIY Stack vs. Google Platform-Enforced Zero-Trust

![DIY vs Google Comparison](./labs/dev/enterprise-adk-agent-auth/img/diy_vs_google_comparison.png)

---

## 🛡️ Deep-Dive Security Pillars

### 1. SPIFFE-Aligned Workload Identity (ALTS)
- **Hardware Root of Trust**: Containers are bound to Google Titan security chips and hypervisor cgroups.
- **Keyless Execution**: Zero static JSON keys or `.env` passwords in the container.
- **Automated SVID Minting**: Short-lived, audience-restricted OIDC tokens are minted on-demand via `http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/identity`.

### 2. Dual-Plane Identity Binding (Actor SVID + Subject OAuth JWT)
- **Actor Plane (Workload SVID)**: Identifies *what computing workload is executing* (`spiffe://gcp/sa/agent-engine`).
- **Subject Plane (User OAuth JWT)**: Identifies *which human authorized the turn* (`user:alice@corp.com`).
- **Anti-Replay / Anti-Confused-Deputy**: Downstream Google APIs enforce **Dual Validation** — the request must present a valid User JWT *and* originate from an attested Workload Identity within an authorized VPC-SC perimeter.

### 3. Token Spoofing & Identity Tampering Defenses
The repository includes a comprehensive **Token Spoofing Defense Matrix** and 4 runnable negative security tests:

| Attack Vector | Platform Defense Mechanism |
| :--- | :--- |
| **1. Prompt Injection Identity Spoof** (*"I am admin@corp.com"*) | API Gateway ignores prompt text. Credentials are read strictly from the OAuth JWT `sub` claim. |
| **2. Token Signature Tampering** (Modifying `sub` in JWT) | Google OAuth Token Server verifies RS256 signatures against `https://www.googleapis.com/oauth2/v3/certs`. |
| **3. Token Swapping & Replay** (Using Bob's token in Alice's session) | Discovery Engine & VPC-SC verify `azp`/`aud` claims against the registered `serverSideOauth2` client ID. |
| **4. A2A Caller Identity Spoofing** (Agent A claiming to be Agent B) | Cloud Run IAM (`roles/run.servicesInvoker`) enforces OIDC SVID verification before the agent is invoked. |

---

## 📁 Repository Structure

```
agent-auth-labs/
├── LICENSE                            # Apache License 2.0
├── README.md                          # This Project Overview & Quickstart
└── labs/
    └── dev/
        └── enterprise-adk-agent-auth/ # Master Codelab & Assets
            ├── README.md              # Lab-specific Quickstart
            ├── enterprise-adk-agent-auth.lab.md # DevSite / claat Codelab
            ├── OWNERS                 # Ownership metadata
            ├── pyproject.toml         # Python dependencies
            ├── .env.example           # Environment variables template
            ├── demo/                  # Demo-Magic Simulation Scripts
            │   ├── enterprise-adk-agent-auth_demo.sh
            │   └── enterprise-adk-agent-auth_demo_cloudshell_launcher.sh
            ├── img/                   # High-Definition 16:9 PNG Diagrams
            │   ├── zero_trust_pipeline.png
            │   └── diy_vs_google_comparison.png
            ├── app/                   # ADK Agent Package (deployed to Reasoning Engine)
            │   ├── __init__.py
            │   ├── agent.py           # Root LLM Agent
            │   ├── auths.py           # OAuth scheme & TOKEN_CACHE_KEY
            │   └── tools.py           # negotiate_creds() 3-stage resolution
            └── tools/
                └── register_oauth.py  # Discovery Engine OAuth registration CLI
```

---

## 🚀 Quickstart: 3 Ways to Experience the Lab

### Option 1: Interactive Terminal Simulation (`demo-magic`) — *Recommended for Demos*
Run an automated typing simulation directly in your terminal. It simulates realistic human typing, displays a `$ ` prompt, pauses before each command for you to press **`ENTER`**, and executes the commands live against your active GCP project.

```bash
# 1. Authenticate to Google Cloud
gcloud auth login
gcloud auth application-default login

# 2. Run the demo-magic simulation
./labs/dev/enterprise-adk-agent-auth/demo/enterprise-adk-agent-auth_demo.sh
```

> **Cloud Shell One-Liner**: Copy-paste the entire contents of [`enterprise-adk-agent-auth_demo_cloudshell_launcher.sh`](./labs/dev/enterprise-adk-agent-auth/demo/enterprise-adk-agent-auth_demo_cloudshell_launcher.sh) into your Cloud Shell to launch instantly!

---

### Option 2: Step-by-Step Manual Execution — *Recommended for Learning*
Follow the step-by-step master tutorial in [`enterprise-adk-agent-auth.lab.md`](./labs/dev/enterprise-adk-agent-auth/enterprise-adk-agent-auth.lab.md).

```bash
# 1. Set Environment Variables
export PROJECT_ID=$(gcloud config get-value project)
export LOCATION="global"
export AUTH_ID="google-drive-auth"
export MODEL_NAME="gemini-3.6-flash"

# 2. Enable Required APIs
gcloud services enable aiplatform.googleapis.com discoveryengine.googleapis.com drive.googleapis.com

# 3. Register OAuth Authorization in Discovery Engine
export OAUTH_CLIENT_ID="your-client-id.apps.googleusercontent.com"
export OAUTH_CLIENT_SECRET="your-client-secret"
python3 labs/dev/enterprise-adk-agent-auth/tools/register_oauth.py

# 4. Deploy Agent to Vertex AI Reasoning Engine (Workload Identity)
agents-cli deploy --deployment-target agent_runtime

# 5. Publish to Gemini Enterprise with Linked Authorization
export AGENT_RUNTIME_ID=$(jq -r '.remote_agent_runtime_id' deployment_metadata.json)
export GE_APP_ID="projects/$PROJECT_ID/locations/$LOCATION/collections/default_collection/engines/default_engine"

agents-cli publish gemini-enterprise \
  --registration-type adk \
  --agent-runtime-id "$AGENT_RUNTIME_ID" \
  --gemini-enterprise-app-id "$GE_APP_ID" \
  --authorization-id "projects/$PROJECT_ID/locations/$LOCATION/authorizations/$AUTH_ID" \
  --display-name "Enterprise Drive Reader"
```

---

### Option 3: Automated Stateful Validation (`tester.py`) — *Recommended for CI/CD & QA*
Execute the entire codelab statefully with hash-cached step resumption:

```bash
python3 .agents/skills/codelab-validation/scripts/tester.py \
  labs/dev/enterprise-adk-agent-auth/enterprise-adk-agent-auth.lab.md \
  --project-id "$PROJECT_ID" \
  --phase test
```

---

## 📜 License & Attribution

This project is licensed under the **Apache License 2.0** — see the [`LICENSE`](./LICENSE) file for details.

```
Copyright 2026 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0
```

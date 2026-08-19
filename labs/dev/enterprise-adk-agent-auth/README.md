# Enterprise ADK Agent Auth: Quickstart & Execution Guide

This repository contains the complete, enterprise-standard codelab and code assets for **Architecting Zero-Trust Identity for AI Agents (Google ADK + GEAP vs DIY Stacks)**.

---

## 🚀 Quickstart: 3 Ways to Run This Codelab

### Option 1: Interactive Terminal Simulation (Demo-Magic) — *Recommended for Demos & Screen Recordings*

Run the automated typing simulation directly in your terminal. The script simulates realistic human typing, pauses before each command for you to press `ENTER`, and executes the commands live against your active GCP project.

```bash
# 1. Ensure you are authenticated to Google Cloud
gcloud auth login
gcloud auth application-default login

# 2. Run the demo-magic simulation
./demo/enterprise-adk-agent-auth_demo.sh
```

---

### Option 2: Step-by-Step Manual Execution — *Recommended for Learning*

Follow the step-by-step master tutorial in [`enterprise-adk-agent-auth.lab.md`](./enterprise-adk-agent-auth.lab.md).

#### Summary of Steps:

```bash
# 1. Set Environment Variables
export PROJECT_ID=$(gcloud config get-value project)
export LOCATION="global"
export AUTH_ID="google-drive-auth"
export MODEL_NAME="gemini-3.6-flash"

# 2. Enable Required APIs
gcloud services enable \
  aiplatform.googleapis.com \
  discoveryengine.googleapis.com \
  drive.googleapis.com \
  --project=$PROJECT_ID

# 3. Configure OAuth 2.0 Credentials in Cloud Console
#    - Go to: https://console.cloud.google.com/apis/credentials
#    - Create an OAuth 2.0 Client ID (Web Application)
#    - Add Authorized Redirect URIs:
#        http://localhost:8501/dev-ui/
#        https://vertexaisearch.cloud.google.com/oauth-redirect

# 4. Register the Authorization Resource with Discovery Engine
export OAUTH_CLIENT_ID="your-client-id.apps.googleusercontent.com"
export OAUTH_CLIENT_SECRET="your-client-secret"
python3 tools/register_oauth.py

# 5. Deploy the Agent to Vertex AI Reasoning Engine (Workload Identity)
agents-cli deploy --deployment-target agent_runtime

# 6. Publish the Agent to Gemini Enterprise with Linked Authorization
export AGENT_RUNTIME_ID=$(jq -r '.remote_agent_runtime_id' deployment_metadata.json)
export GE_APP_ID="projects/$PROJECT_ID/locations/$LOCATION/collections/default_collection/engines/default_engine"

agents-cli publish gemini-enterprise \
  --registration-type adk \
  --agent-runtime-id "$AGENT_RUNTIME_ID" \
  --gemini-enterprise-app-id "$GE_APP_ID" \
  --authorization-id "projects/$PROJECT_ID/locations/$LOCATION/authorizations/$AUTH_ID" \
  --display-name "Enterprise Drive Reader"

# 7. Test in Gemini Enterprise Web UI!
#    Ask: "Summarize the file with ID <YOUR_DRIVE_FILE_ID>"

# 8. Run Negative Security & Spoofing Tests
#    See Section 8 of enterprise-adk-agent-auth.lab.md for the 4 attack simulations.

# 9. Clean Up
agents-cli publish gemini-enterprise --unregister \
  --agent-runtime-id "$AGENT_RUNTIME_ID" \
  --gemini-enterprise-app-id "$GE_APP_ID"

curl -X DELETE \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "X-Goog-User-Project: $PROJECT_ID" \
  "https://discoveryengine.googleapis.com/v1alpha/projects/$PROJECT_ID/locations/$LOCATION/authorizations/$AUTH_ID"

curl -X DELETE \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "X-Goog-User-Project: $PROJECT_ID" \
  "https://us-east1-aiplatform.googleapis.com/v1/$AGENT_RUNTIME_ID"
```

---

### Option 3: Automated Stateful Validation (`tester.py`) — *Recommended for CI/CD & QA*

Execute the entire codelab statefully using the `tester.py` validation engine:

```bash
python3 .agents/skills/codelab-validation/scripts/tester.py \
  labs/dev/enterprise-adk-agent-auth/enterprise-adk-agent-auth.lab.md \
  --project-id "$PROJECT_ID" \
  --phase test
```

---

## 📁 Repository Structure

```
.
├── README.md                          # This Quickstart Guide
├── enterprise-adk-agent-auth.lab.md   # Master step-by-step Codelab
├── OWNERS                             # Ownership metadata
├── pyproject.toml                     # Python dependencies
├── .env.example                       # Environment variables template
├── demo/                              # Demo-Magic Simulation Scripts
│   ├── enterprise-adk-agent-auth_demo.sh
│   └── enterprise-adk-agent-auth_demo_cloudshell_launcher.sh
├── img/                               # High-Definition 16:9 PNG Diagrams
│   ├── zero_trust_pipeline.png
│   └── diy_vs_google_comparison.png
├── app/                               # ADK Agent Package (deployed to Reasoning Engine)
│   ├── __init__.py
│   ├── agent.py                       # Root Agent definition
│   ├── auths.py                       # OAuth scheme & TOKEN_CACHE_KEY
│   └── tools.py                       # negotiate_creds() 3-stage resolution
└── tools/
    └── register_oauth.py              # Discovery Engine OAuth registration CLI
```

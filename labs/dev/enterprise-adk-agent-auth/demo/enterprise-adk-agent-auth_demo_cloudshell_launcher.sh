cat << 'EOF' > enterprise-adk-agent-auth_demo.sh
#!/usr/bin/env bash
###############################################################################
# Generated Demo-Magic Presentation Script
# Compiles codelab instructions into interactive humanized typing flows.
###############################################################################

# Configuration
TYPE_SPEED=20
DEMO_PROMPT="$ "

# Core System Parameters & Variables
# Automatically resolves to active Google Cloud Shell project context if set
PROJECT_ID=${PROJECT_ID:-$GOOGLE_CLOUD_PROJECT}
REGION=${REGION:-"us-central1"}
ZONE=${ZONE:-"us-central1-a"}


DEMO_CMD_COLOR="\033[1;36m"      # Bold Cyan
DEMO_COMMENT_COLOR="\033[0;90m" # Grey
COLOR_RESET="\033[0m"

function wait_for_enter() {
  read -rs
}

function simulate_typing() {
  local text="$1"
  local color="$2"
  local len=${#text}
  
  local delay=0.05
  if [[ "$TYPE_SPEED" -gt 0 ]]; then
    if [[ "$TYPE_SPEED" -ge 40 ]]; then delay=0.02
    elif [[ "$TYPE_SPEED" -ge 30 ]]; then delay=0.03
    elif [[ "$TYPE_SPEED" -ge 25 ]]; then delay=0.04
    elif [[ "$TYPE_SPEED" -ge 20 ]]; then delay=0.05
    elif [[ "$TYPE_SPEED" -ge 15 ]]; then delay=0.06
    elif [[ "$TYPE_SPEED" -ge 10 ]]; then delay=0.10
    else delay=0.15
    fi
  else
    delay=0
  fi

  for (( i=0; i<len; i++ )); do
    echo -ne "${color}${text:$i:1}${COLOR_RESET}"
    if [[ "$delay" != "0" ]]; then
      sleep "$delay"
    fi
  done
}

function pe() {
  local cmd="$1"
  echo -ne "${DEMO_PROMPT}"
  simulate_typing "$cmd" "${DEMO_CMD_COLOR}"
  wait_for_enter
  echo ""
  eval "$cmd"
  echo ""
}

function p() {
  local cmd="$1"
  echo -ne "${DEMO_PROMPT}"
  simulate_typing "$cmd" "${DEMO_COMMENT_COLOR}"
  wait_for_enter
  echo ""
}

# Clear screen at start for pristine presentation canvas
clear
echo -e "${DEMO_COMMENT_COLOR}# Starting interactive demonstration session...${COLOR_RESET}\n"

pe "export PROJECT_ID=$(gcloud config get-value project)"
pe "export LOCATION=\"global\""
pe "export AUTH_ID=\"google-drive-auth\""
pe "export MODEL_NAME=\"gemini-3.6-flash\""
pe "gcloud config set project $PROJECT_ID"
pe "gcloud services enable aiplatform.googleapis.com discoveryengine.googleapis.com drive.googleapis.com --project=$PROJECT_ID"
pe "export OAUTH_CLIENT_ID=\"your-client-id.apps.googleusercontent.com\""
pe "export OAUTH_CLIENT_SECRET=\"your-client-secret\""
pe "python3 tools/register_oauth.py"
pe "curl -s -H \"Authorization: Bearer $(gcloud auth print-access-token)\" -H \"X-Goog-User-Project: $PROJECT_ID\" \"https://discoveryengine.googleapis.com/v1alpha/projects/$PROJECT_ID/locations/$LOCATION/authorizations/$AUTH_ID\" | python3 -m json.tool"
pe "agents-cli deploy --deployment-target agent_runtime"
pe "export AGENT_RUNTIME_ID=$(jq -r '.remote_agent_runtime_id' deployment_metadata.json)"
pe "export GE_APP_ID=\"projects/$PROJECT_ID/locations/$LOCATION/collections/default_collection/engines/default_engine\""
pe "agents-cli publish gemini-enterprise --registration-type adk --agent-runtime-id \"$AGENT_RUNTIME_ID\" --gemini-enterprise-app-id \"$GE_APP_ID\" --authorization-id \"projects/$PROJECT_ID/locations/$LOCATION/authorizations/$AUTH_ID\" --display-name \"Enterprise Drive Reader\" --description \"Reads Google Drive files on behalf of authenticated users\""
p "# Test command: Attempting to use a tampered JWT"
pe "python3 -c \""
pe "from app.tools import read_drive_file"
pe "from google.adk.tools import ToolContext"
p "# Create a tampered JWT with modified 'sub'"
pe "tampered_jwt = 'eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJib2JAY29ycC5jb20ifQ.invalid_signature'"
pe "ctx = ToolContext(state={'temp:google-drive-auth': tampered_jwt})"
pe "result = read_drive_file('1a2b3c', ctx)"
pe "print(result)"
pe "\""
p "# Test command: Attempting to use a token from an unauthorized Client ID"
pe "python3 -c \""
p "# Token issued for Client ID '12345-other.apps.googleusercontent.com'"
pe "foreign_token = 'ya29.a0Axoo...other_client'"
pe "ctx = ToolContext(state={'temp:google-drive-auth': foreign_token})"
pe "result = read_drive_file('1a2b3c', ctx)"
pe "print(result)"
pe "\""
p "# Test command: Spoofed A2A call without OIDC SVID"
pe "curl -X POST \"https://my-agent-service-abc123.us-east1.run.app/a2a/app/invoke\" -H \"Content-Type: application/json\" -H \"X-Caller-Identity: orchestrator@project.iam.gserviceaccount.com\" -d '{\"prompt\": \"Delete all records\"}'"

echo -e "${DEMO_COMMENT_COLOR}# Demonstration complete.${COLOR_RESET}"
EOF
chmod +x enterprise-adk-agent-auth_demo.sh
./enterprise-adk-agent-auth_demo.sh

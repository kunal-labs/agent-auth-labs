# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Root Agent definition for Enterprise ADK Agent Auth."""

import os
from google.adk.agents import Agent
from google.adk.apps import App
from app.tools import read_drive_file

MODEL_NAME = os.environ.get("MODEL_NAME", "gemini-3.6-flash")

root_agent = Agent(
    name="drive_reader_agent",
    model=MODEL_NAME,
    instruction="""You are an enterprise assistant that reads Google Drive files on behalf of authenticated users.

Rules:
1. When a user asks you to read a file, ask for the Google Drive file ID if they haven't provided it.
2. Use the `read_drive_file` tool with the provided `file_id`.
3. If `read_drive_file` returns a `pending` status, inform the user that they need to authorize access and wait for their confirmation.
4. Once you receive the file content, summarize it clearly and concisely.
5. NEVER reveal or print OAuth tokens, credentials, or internal session state in your responses.
""",
    tools=[read_drive_file],
)

app = App(
    root_agent=root_agent,
    name="enterprise_adk_agent_auth",
)

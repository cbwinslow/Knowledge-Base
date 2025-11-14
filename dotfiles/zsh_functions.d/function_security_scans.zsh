# ==============================================================================
#
# FILENAME: function_security_scans.zsh
#
# AUTHOR: Gemini (Modified by foomanchu8008)
# DATE: 2025-10-25
#
# TYPE: Zsh Function Library
#
# PURPOSE:
#   Provides a suite of functions for running system security scans.
#
# SUMMARY:
#   This script contains functions to automate security scanning tools, format
#   their output, and provide workflows for further analysis.
#
# ==============================================================================
#
# FUNCTION: analyze_chkrootkit_report
#
# DESCRIPTION:
#   This function executes 'chkrootkit' to scan for rootkits. It then
#   constructs a 'curl' command to send the scan report to an AI model for
#   analysis, fetching the required API key securely from a Bitwarden vault
#   using the 'bw' CLI.
#
# USAGE:
#   > analyze_chkrootkit_report
#
# BITWARDEN SETUP:
#   This function requires a secret named "OPENROUTER_API_KEY" in your Bitwarden vault.
#   Create a "Login" item with:
#     - Name: OPENROUTER_API_KEY
#     - Password: Your OpenRouter API Key
#
# INPUTS:
#   None. Fetches credentials directly from Bitwarden.
#
# OUTPUTS:
#   - A message indicating the start of the scan.
#   - The path to the saved report file.
#   - A 'curl' command for AI analysis.
#   - Error messages if dependencies (jq, chkrootkit, bw) are missing or if
#     the API key cannot be fetched from Bitwarden.
#
# CHANGELOG:
#   - 2025-10-25: Initial creation with env var for key.
#   - 2025-10-25: Added dependency checks and improved error handling.
#   - 2025-10-25: Integrated with Bitwarden CLI ('bw') for secure API key fetching.
#   - 2025-10-25: Updated to use 'OPENROUTER_API_KEY' as the Bitwarden item name.
#
# ==============================================================================
analyze_chkrootkit_report() {
  # --- Dependency Validation ---
  for cmd in jq chkrootkit bw; do
    if ! command -v "$cmd" &> /dev/null; then
      echo "❌ Error: Command '$cmd' is not installed. Please install it to continue."
      return 1
    fi
  done

  # --- Fetch API Key from Bitwarden ---
  echo "🔐 Fetching OpenRouter API key from Bitwarden..."
  local openrouter_key
  # Use 'bw get password' to retrieve the key from an item named "OPENROUTER_API_KEY".
  # The '|| true' prevents the script from exiting if bw fails (e.g., vault locked),
  # allowing us to handle the error gracefully.
  openrouter_key=$(bw get password "OPENROUTER_API_KEY" || true)

  # Check if the key was successfully retrieved.
  if [ -z "$openrouter_key" ]; then
    echo "❌ Error: Could not fetch API key from Bitwarden."
    echo "   Please ensure you are logged into the 'bw' CLI and have a secret named 'OPENROUTER_API_KEY'."
    return 1
  fi
  echo "✅ API key fetched successfully."


  # Announce the start of the operation to the user.
  echo "🚀 Starting chkrootkit scan. This may take a few minutes..."

  # --- Report File Setup ---
  local report_path="/tmp/chkrootkit_report_$(date +%Y-%m-%d_%H-%M-%S).txt"

  # --- Execute Scan ---
  sudo chkrootkit > "$report_path" 2>&1

  # --- Verify Scan Success & Proceed ---
  if [ $? -eq 0 ]; then
    echo "✅ Scan complete. Report saved to: $report_path"
    echo "\n"
    echo "🤖 To analyze this report with an AI, copy and run the following command:"
    echo "\n"

    local report_content
    report_content=$(jq -Rs . < "$report_path")

    # --- Construct and Display Curl Command ---
    # Use the '$openrouter_key' variable fetched from Bitwarden.
    echo "curl -s -X POST https://openrouter.ai/api/v1/chat/completions \
  -H \"Authorization: Bearer $openrouter_key\" \
  -H \"Content-Type: application/json\" \
  -d '{
    \"model\": \"mistralai/mistral-7b-instruct:free\",
    \"messages\": [
      {
        \"role\": \"system\",
        \"content\": \"You are an expert cybersecurity analyst. Your task is to analyze the following chkrootkit report. Identify any potential threats, explain what they mean, and clearly distinguish between genuine threats and likely false positives. Provide a concise summary of the findings and recommend actions if necessary.\"
      },
      {
        \"role\": \"user\",
        \"content\": ${report_content}
      }
    ]
  }' | jq -r '.choices[0].message.content'"

  else
    echo "❌ Error running chkrootkit. Check the log for details: $report_path"
  fi
}

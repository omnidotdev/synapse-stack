#!/usr/bin/env bash
# Synapse Gateway Smoke Test
#
# Usage: ./scripts/smoke-test.sh [base_url]
# Default: http://localhost:6000

set -euo pipefail

BASE="${1:-http://localhost:6000}"
PASS=0
FAIL=0
SKIP=0

green() { printf '\033[32m%s\033[0m\n' "$*"; }
red()   { printf '\033[31m%s\033[0m\n' "$*"; }
yellow(){ printf '\033[33m%s\033[0m\n' "$*"; }

check() {
    local name="$1" endpoint="$2" method="${3:-GET}" body="${4:-}"
    local args=(-s -o /tmp/synapse-smoke-body -w '%{http_code}' -X "$method")

    if [[ -n "$body" ]]; then
        args+=(-H 'Content-Type: application/json' -d "$body")
    fi

    local status
    status=$(curl "${args[@]}" "${BASE}${endpoint}" 2>/dev/null) || status="000"

    if [[ "$status" =~ ^2 ]]; then
        green "  PASS  $name ($status)"
        PASS=$((PASS + 1))
    elif [[ "$status" == "000" ]]; then
        red "  FAIL  $name (connection refused)"
        FAIL=$((FAIL + 1))
    else
        red "  FAIL  $name ($status)"
        cat /tmp/synapse-smoke-body 2>/dev/null | head -3
        echo
        FAIL=$((FAIL + 1))
    fi
}

check_optional() {
    local name="$1" endpoint="$2" method="${3:-GET}" body="${4:-}"
    local args=(-s -o /tmp/synapse-smoke-body -w '%{http_code}' -X "$method")

    if [[ -n "$body" ]]; then
        args+=(-H 'Content-Type: application/json' -d "$body")
    fi

    local status
    status=$(curl "${args[@]}" "${BASE}${endpoint}" 2>/dev/null) || status="000"

    if [[ "$status" =~ ^2 ]]; then
        green "  PASS  $name ($status)"
        PASS=$((PASS + 1))
    else
        yellow "  SKIP  $name ($status) - provider may not be configured"
        SKIP=$((SKIP + 1))
    fi
}

echo "Synapse Gateway Smoke Test"
echo "Target: $BASE"
echo "---"

echo
echo "Core endpoints:"
check "Health" "/health"
check "Models" "/v1/models"

echo
echo "LLM (chat completions):"
check "Non-streaming chat" "/v1/chat/completions" POST \
    '{"model":"auto","messages":[{"role":"user","content":"Say hi in 3 words"}]}'

# Streaming test - check we get SSE back
echo -n "  "
STATUS=$(curl -s -o /tmp/synapse-smoke-stream -w '%{http_code}' \
    -H 'Content-Type: application/json' \
    -d '{"model":"auto","messages":[{"role":"user","content":"Say hi in 3 words"}],"stream":true}' \
    "${BASE}/v1/chat/completions" 2>/dev/null) || STATUS="000"

if [[ "$STATUS" =~ ^2 ]] && grep -q 'data: ' /tmp/synapse-smoke-stream 2>/dev/null; then
    green "PASS  Streaming chat ($STATUS, SSE confirmed)"
    PASS=$((PASS + 1))
elif [[ "$STATUS" == "000" ]]; then
    red "FAIL  Streaming chat (connection refused)"
    FAIL=$((FAIL + 1))
else
    red "FAIL  Streaming chat ($STATUS)"
    FAIL=$((FAIL + 1))
fi

echo
echo "Embeddings:"
check_optional "Generate embeddings" "/v1/embeddings" POST \
    '{"model":"openai/text-embedding-3-small","input":"Hello world"}'

echo
echo "Image generation:"
check_optional "Generate image" "/v1/images/generations" POST \
    '{"model":"openai/dall-e-3","prompt":"A red circle on white background","size":"1024x1024","n":1}'

echo
echo "Speech-to-text:"
# STT requires multipart, just check endpoint exists
STATUS=$(curl -s -o /dev/null -w '%{http_code}' -X POST "${BASE}/v1/audio/transcriptions" 2>/dev/null) || STATUS="000"
if [[ "$STATUS" == "400" || "$STATUS" =~ ^2 ]]; then
    green "  PASS  STT endpoint reachable ($STATUS)"
    PASS=$((PASS + 1))
elif [[ "$STATUS" == "000" ]]; then
    red "  FAIL  STT endpoint (connection refused)"
    FAIL=$((FAIL + 1))
else
    yellow "  SKIP  STT endpoint ($STATUS)"
    SKIP=$((SKIP + 1))
fi

echo
echo "Text-to-speech:"
check_optional "Synthesize speech" "/v1/audio/speech" POST \
    '{"model":"openai/tts-1","input":"Hello","voice":"alloy"}'

echo
echo "MCP:"
check_optional "List tools" "/mcp/tools/list" POST '{}'
check_optional "Search tools" "/mcp/search?q=test"

echo
echo "API Key Auth:"
# Test that gateway rejects unauthenticated requests when auth is enabled
# and that synapse-api's /internal/resolve-key endpoint is reachable
API_URL="${API_BASE:-https://localhost:4000}"

# Test 1: Check if synapse-api internal endpoint is reachable
API_RESOLVE_STATUS=$(curl -sk -o /tmp/synapse-smoke-resolve -w '%{http_code}' \
    -X POST \
    -H 'Content-Type: application/json' \
    -H "X-Gateway-Secret: ${GATEWAY_SECRET:-}" \
    -d '{"key":"sk-syn-0000000000000000000000000000dead"}' \
    "${API_URL}/internal/resolve-key" 2>/dev/null) || API_RESOLVE_STATUS="000"

if [[ "$API_RESOLVE_STATUS" == "000" ]]; then
    yellow "  SKIP  API key resolution (synapse-api not running at ${API_URL})"
    SKIP=$((SKIP + 1))
elif [[ "$API_RESOLVE_STATUS" == "401" ]]; then
    yellow "  SKIP  API key resolution (GATEWAY_SECRET not set or mismatched)"
    SKIP=$((SKIP + 1))
elif [[ "$API_RESOLVE_STATUS" == "404" ]]; then
    # 404 means the endpoint works but the key doesn't exist - that's correct
    green "  PASS  API key resolution endpoint (correctly rejects unknown key)"
    PASS=$((PASS + 1))
elif [[ "$API_RESOLVE_STATUS" =~ ^2 ]]; then
    green "  PASS  API key resolution endpoint ($API_RESOLVE_STATUS)"
    PASS=$((PASS + 1))
else
    red "  FAIL  API key resolution endpoint ($API_RESOLVE_STATUS)"
    cat /tmp/synapse-smoke-resolve 2>/dev/null | head -3
    echo
    FAIL=$((FAIL + 1))
fi

# Test 2: Gateway should reject a fake sk-syn- key with 401
GATEWAY_AUTH_STATUS=$(curl -s -o /tmp/synapse-smoke-auth -w '%{http_code}' \
    -H 'Content-Type: application/json' \
    -H 'Authorization: Bearer sk-syn-0000000000000000000000000000dead' \
    -d '{"model":"auto","messages":[{"role":"user","content":"test"}]}' \
    "${BASE}/v1/chat/completions" 2>/dev/null) || GATEWAY_AUTH_STATUS="000"

if [[ "$GATEWAY_AUTH_STATUS" == "401" ]]; then
    green "  PASS  Gateway rejects invalid API key (401)"
    PASS=$((PASS + 1))
elif [[ "$GATEWAY_AUTH_STATUS" == "000" ]]; then
    yellow "  SKIP  Gateway auth test (gateway not running)"
    SKIP=$((SKIP + 1))
else
    yellow "  SKIP  Gateway auth test (got $GATEWAY_AUTH_STATUS, auth may be disabled)"
    SKIP=$((SKIP + 1))
fi

echo
echo "---"
echo "Results: ${PASS} passed, ${FAIL} failed, ${SKIP} skipped"

if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi

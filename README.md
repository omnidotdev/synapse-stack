# Synapse

AI inference router for unified LLM, MCP, STT, and TTS provider management.

## Architecture

| Service | Stack | Port | Role |
|---------|-------|------|------|
| **synapse-gateway** | Rust (axum) | 6000 | AI inference router |
| **synapse-api** | TS (Elysia + Drizzle + PostGraphile) | 4000 | GraphQL backend for dashboard |
| **synapse-app** | TS (TanStack Start + React) | 3000 | Dashboard UI |

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  synapse-app │────>│  synapse-api │     │   Clients    │
│  (dashboard) │     │  (GraphQL)   │     │ (CLI/Beacon) │
└──────────────┘     └──────┬───────┘     └──────┬───────┘
                            │                    │
                            ▼                    ▼
                     ┌─────────────────────────────┐
                     │      synapse-gateway         │
                     │   (LLM/MCP/STT/TTS router)  │
                     └──────┬──────┬──────┬────────┘
                            │      │      │
                     ┌──────┘  ┌───┘  ┌───┘
                     ▼         ▼      ▼
                  Anthropic  OpenAI  Google ...
```

## Quick Start

### Prerequisites

- [Rust](https://rustup.rs/) (for gateway)
- [Bun](https://bun.sh/) (for API and app)
- [Tilt](https://tilt.dev/) (for orchestration)
- PostgreSQL (for API)

### Development

1. Copy the environment template and add your API keys:

```bash
cp .env.local.example .env.local
# Edit .env.local with your ANTHROPIC_API_KEY, OPENAI_API_KEY, etc.
```

2. Copy the services configuration:

```bash
cp services.yaml.template services.yaml
```

3. Start all services:

```bash
tilt up
```

This builds and starts:
- **synapse-gateway** at `http://localhost:6000`
- **synapse-api** at `http://localhost:4000`
- **synapse-app** at `http://localhost:3000`

### Running Services Individually

**Gateway:**
```bash
cd services/synapse-gateway
cargo run -p synapse -- --config ../../config/synapse.dev.toml
```

**API:**
```bash
cd services/synapse-api
bun i && bun dev
```

**App:**
```bash
cd services/synapse-app
bun i && bun dev
```

## Configuration

Gateway configuration uses TOML with environment variable interpolation (`{{ env.VAR }}`):

```toml
[server]
listen_address = "127.0.0.1:6000"

[llm.providers.anthropic]
type = "anthropic"
api_key = "{{ env.ANTHROPIC_API_KEY }}"

[llm.providers.openai]
type = "openai"
api_key = "{{ env.OPENAI_API_KEY }}"
```

See `config/synapse.dev.toml` for the full development configuration.

## Environment Variables

### Gateway

| Variable | Description | Default |
|----------|-------------|---------|
| `ANTHROPIC_API_KEY` | Anthropic API key | - |
| `OPENAI_API_KEY` | OpenAI API key | - |
| `GATEWAY_SECRET` | Shared secret for API↔gateway auth | - |

### API

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | - |
| `AUTH_BASE_URL` | Auth provider (Gatekeeper) URL | `https://localhost:8000` |
| `ENCRYPTION_KEY` | Key for encrypting provider keys at rest | - |
| `GATEWAY_SECRET` | Shared secret for gateway auth | - |
| `CORS_ALLOWED_ORIGINS` | Comma-separated CORS origins | - |
| `PROTECT_ROUTES` | Require auth for GraphQL routes | `false` |

### App

| Variable | Description | Default |
|----------|-------------|---------|
| `VITE_API_URL` | synapse-api GraphQL endpoint | - |
| `VITE_AUTH_URL` | Auth provider URL | - |

## Features

- **Multi-provider LLM routing**: Anthropic, OpenAI, Google, AWS Bedrock
- **Smart routing**: Threshold, cost, cascade, score, and ONNX ML strategies
- **Automatic failover**: Circuit breaker with configurable equivalence groups
- **MCP integration**: STDIO, SSE, and Streamable HTTP transports
- **STT/TTS**: Whisper, Deepgram, OpenAI TTS, ElevenLabs
- **Embeddings and image generation**: via OpenAI
- **API key management**: Dashboard for managing provider keys
- **Usage tracking**: Per-model, per-provider usage analytics
- **Security**: JWT auth, CSRF protection, rate limiting, GraphQL armor

## Health Checks

| Service | Endpoint | Port |
|---------|----------|------|
| Gateway | `GET /health` | 6000 |
| API | `GET /health` | 4000 |
| API | `GET /ready` | 4000 |

## Deployment

All services have production Dockerfiles:

```bash
# Gateway (Chainguard base, non-root)
docker build -t synapse-gateway services/synapse-gateway

# API (Bun)
docker build -t synapse-api services/synapse-api

# App (Node runtime — see Dockerfile for Bun workaround)
docker build -t synapse-app services/synapse-app
```

## Database

synapse-api uses Drizzle ORM with PostgreSQL:

```bash
cd services/synapse-api
bun db:generate  # Generate migrations
bun db:migrate   # Apply migrations
```

## Testing

```bash
# Gateway
cd services/synapse-gateway && cargo test

# API
cd services/synapse-api && bun test

# App (unit + component)
cd services/synapse-app && bun test src

# App (E2E)
cd services/synapse-app && bun test:e2e
```

## Integration

Synapse is consumed by:

- **[Beacon](https://github.com/omnidotdev/beacon-gateway)**: Routes LLM, STT/TTS, and tool execution through Synapse
- **[Omni CLI](https://github.com/omnidotdev/cli)**: Uses Synapse for model discovery and unified provider access

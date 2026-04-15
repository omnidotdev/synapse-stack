<div align="center">

# Synapse

Unified AI router for LLM, embeddings, image generation, MCP, STT, and TTS

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE.md)

</div>

## Overview

Synapse routes all AI traffic through a single configurable gateway. Point any OpenAI or Anthropic SDK at a Synapse instance, configure your provider keys once, and let Synapse handle provider selection, failover, rate limiting, usage metering, and observability.

## Services

| Service | Description |
|---------|-------------|
| [synapse](https://github.com/omnidotdev/synapse) | Rust AI inference gateway |
| [synapse-api](https://github.com/omnidotdev/synapse-api) | GraphQL API (Elysia) |
| [synapse-app](https://github.com/omnidotdev/synapse-app) | Dashboard (TanStack Start) |

## Getting Started

1. Copy configuration templates:

   ```sh
   cp services.yaml.template services.yaml
   cp .env.local.template .env.local
   ```

2. Edit `.env.local` with at least one provider API key and the required secrets (`GATEWAY_SECRET`, `ENCRYPTION_KEY`, `AUTH_SECRET`)

3. Start development:

   ```sh
   tilt up
   ```

## Self-Hosting

Each service includes a Dockerfile. The provided `compose.yaml` builds and runs the full stack:

```sh
docker compose up --build
```

See `.env.local.template` for all configuration options and `charts/synapse/` for the Helm chart.

## Ecosystem

- **[Beacon](https://github.com/omnidotdev/beacon)** consumes Synapse as its LLM, STT/TTS, and tool execution gateway
- **[Omni CLI](https://github.com/omnidotdev/cli)** uses Synapse for model discovery and unified provider access
- **[Aether](https://github.com/omnidotdev/aether)** handles billing metering for managed and credit billing modes
- **[Warden](https://github.com/omnidotdev/warden)** enforces authorization on API and dashboard routes

## License

The code in this repository is licensed under Apache 2.0, &copy; [Omni LLC](https://omni.dev). See [LICENSE.md](LICENSE.md) for more information.

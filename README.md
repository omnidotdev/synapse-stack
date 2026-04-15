<div align="center">

# 🧠 Synapse

[Website](https://synapse.omni.dev) | [Docs](https://docs.omni.dev/docs/grid/synapse) | [Feedback](https://github.com/omnidotdev/synapse-stack/issues) | [Discord](https://discord.gg/omnidotdev) | [X](https://x.com/omnidotdev)

</div>

**Synapse** is a unified AI router for LLM, embeddings, image generation, MCP, STT, and TTS.

## Services

| Service | Description |
|---------|-------------|
| [synapse](https://github.com/omnidotdev/synapse) | Rust AI inference gateway |
| [synapse-api](https://github.com/omnidotdev/synapse-api) | GraphQL API (Elysia) |
| [synapse-app](https://github.com/omnidotdev/synapse-app) | Dashboard (TanStack Start) |

## Getting Started

### Prerequisites

- [Tilt](https://tilt.dev)

### Setup

1. Copy configuration templates:

   ```sh
   cp services.yaml.template services.yaml
   ```

2. Configure services as needed. To disable a service, comment it out. Any included services will be locally cloned.

3. Start the development environment:

   ```sh
   tilt up
   ```

> ⚠️ Services have their own setup requirements (e.g. environment variables). Consult each service's README to ensure all initial requirements are satisfied.

### Diagnostics

Open the [Tilt dashboard](http://localhost:10350) to view service status, logs, and resource health.

### Configuration

Each service in `services.yaml` can specify:

| Key | Description |
|-----|-------------|
| `url` | Git repository URL for cloning |
| `path` | Local path override (defaults to `services/service-name`) |

> 💡 If nested repos are cloned within this metarepo and you open it in your IDE, directories may be marked as ignored due to `.gitignore` patterns. To work around this, open services in their own directory (e.g., a separate VS Code workspace unit).

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

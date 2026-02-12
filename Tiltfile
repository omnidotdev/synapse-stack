# Synapse Development Orchestration
#
# Usage:
#   tilt up    - Start all services
#   tilt down  - Stop all services

load("ext://git_resource", "git_checkout")
load("ext://dotenv", "dotenv")
load("ext://color", "color")

# Load environment
if os.path.exists(".env.local"):
    dotenv(fn=".env.local")

# Read service configuration
config_path = "services.yaml"
if not os.path.exists(config_path):
    fail("Missing services.yaml - copy from services.yaml.template")

services = read_yaml(config_path).get("services", [])

# ------------------------------------
# Bootstrap services
# ------------------------------------
for service in services:
    name = service.keys()[0]
    values = service.values()[0]
    repo = values.get("repo", "")
    path = values.get("path", "services/%s" % name)

    if repo and not os.path.exists(path):
        print(color.yellow("%s does not exist, cloning..." % path))
        git_checkout(repo, path)
    elif os.path.exists(path):
        print(color.green("%s already exists" % path))

# ------------------------------------
# Synapse gateway
# ------------------------------------
gateway_path = "services/synapse-gateway"
config = os.path.abspath("config/synapse.dev.toml") if os.path.exists("config/synapse.dev.toml") else ""

if os.path.exists(gateway_path):
    local_resource(
        "build-synapse-gateway",
        cmd="cargo build -p synapse",
        dir=gateway_path,
        deps=[
            "%s/synapse/src" % gateway_path,
            "%s/crates" % gateway_path,
            "%s/Cargo.toml" % gateway_path,
        ],
        labels=["synapse-gateway"],
    )

    serve_cmd = "cargo run -p synapse"
    if config:
        serve_cmd = "%s -- --config %s" % (serve_cmd, config)

    local_resource(
        "dev-synapse-gateway",
        serve_cmd=serve_cmd,
        serve_dir=gateway_path,
        resource_deps=["build-synapse-gateway"],
        readiness_probe=probe(
            http_get=http_get_action(
                path="/health",
                port=6000,
            ),
            initial_delay_secs=5,
            period_secs=5,
        ),
        labels=["synapse-gateway"],
    )
else:
    print(color.yellow("synapse-gateway not found - run services bootstrap first"))

# ------------------------------------
# Synapse API
# ------------------------------------
api_path = "services/synapse-api"

if os.path.exists(api_path):
    local_resource(
        "install-synapse-api",
        cmd="bun i",
        dir=api_path,
        deps=["%s/package.json" % api_path],
        labels=["synapse-api"],
    )

    local_resource(
        "dev-synapse-api",
        serve_cmd="bun dev",
        serve_dir=api_path,
        resource_deps=["install-synapse-api"],
        readiness_probe=probe(
            http_get=http_get_action(
                path="/health",
                port=4000,
            ),
            initial_delay_secs=3,
            period_secs=5,
        ),
        labels=["synapse-api"],
    )
else:
    print(color.yellow("synapse-api not found - run services bootstrap first"))

# ------------------------------------
# Synapse app (dashboard)
# ------------------------------------
app_path = "services/synapse-app"

if os.path.exists(app_path):
    if os.path.exists("%s/Tiltfile" % app_path):
        include(os.path.join(app_path, "Tiltfile"))
    else:
        local_resource(
            "dev-synapse-app",
            serve_cmd="bun dev",
            serve_dir=app_path,
            labels=["synapse-app"],
        )
else:
    print(color.yellow("synapse-app not found - run services bootstrap first"))

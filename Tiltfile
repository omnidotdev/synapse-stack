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
# Synapse server
# ------------------------------------
server_path = "services/synapse-server"
config = os.path.abspath("config/synapse.dev.toml") if os.path.exists("config/synapse.dev.toml") else ""

if os.path.exists(server_path):
    local_resource(
        "build-synapse-server",
        cmd="cargo build -p synapse",
        dir=server_path,
        deps=[
            "%s/synapse/src" % server_path,
            "%s/crates" % server_path,
            "%s/Cargo.toml" % server_path,
        ],
        labels=["synapse-server"],
    )

    serve_cmd = "cargo run -p synapse"
    if config:
        serve_cmd = "%s -- --config %s" % (serve_cmd, config)

    local_resource(
        "dev-synapse-server",
        serve_cmd=serve_cmd,
        serve_dir=server_path,
        resource_deps=["build-synapse-server"],
        readiness_probe=probe(
            http_get=http_get_action(
                path="/health",
                port=6000,
            ),
            initial_delay_secs=5,
            period_secs=5,
        ),
        labels=["synapse-server"],
    )
else:
    print(color.yellow("synapse-server not found - run services bootstrap first"))

# ------------------------------------
# Synapse dashboard
# ------------------------------------
dashboard_path = "services/synapse-dashboard"

if os.path.exists(dashboard_path):
    if os.path.exists("%s/Tiltfile" % dashboard_path):
        include(os.path.join(dashboard_path, "Tiltfile"))
else:
    print(color.yellow("synapse-dashboard not found - run services bootstrap first"))

# ------------------------------------
# Synapse API
# ------------------------------------
api_path = "services/synapse-api"

if os.path.exists(api_path):
    if os.path.exists("%s/Tiltfile" % api_path):
        include(os.path.join(api_path, "Tiltfile"))
else:
    print(color.yellow("synapse-api not found - run services bootstrap first"))

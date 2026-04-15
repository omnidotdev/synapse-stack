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

    # Handle metarepos - auto-discover services in {path}/services/*/Tiltfile
    if values.get("metarepo", False):
        base_path = values.get("path", "services/%s" % name)
        repo = values.get("repo")

        # Expand ~ to home directory
        if base_path.startswith("~"):
            base_path = base_path.replace("~", os.environ["HOME"])

        # Clone if repo specified and path doesn't exist
        if repo and not os.path.exists(base_path):
            print(color.yellow("%s does not exist, cloning..." % base_path))
            git_checkout(repo, base_path)
        elif os.path.exists(base_path):
            print(color.green("%s already exists" % base_path))

        # Auto-discover services using shell
        services_dir = "%s/services" % base_path
        if os.path.exists(services_dir):
            sub_services = str(local("ls %s" % services_dir, quiet=True)).strip().split("\n")
            for sub_service in sub_services:
                if sub_service:
                    sub_path = "%s/%s" % (services_dir, sub_service)
                    tiltfile_path = "%s/Tiltfile" % sub_path
                    if os.path.exists(tiltfile_path):
                        print(color.green("     Loading Tiltfile for %s..." % sub_service))
                        include(tiltfile_path)
        continue

    repo = values.get("repo", "")
    path = values.get("path", "services/%s" % name)

    # Expand ~ to home directory
    if path.startswith("~"):
        path = path.replace("~", os.environ["HOME"])

    if repo and not os.path.exists(path):
        print(color.yellow("%s does not exist, cloning..." % path))
        git_checkout(repo, path)
    elif os.path.exists(path):
        print(color.green("%s already exists" % path))

# ------------------------------------
# Synapse gateway
# ------------------------------------
gateway_path = "services/synapse"
config = os.path.abspath("config/synapse.dev.toml") if os.path.exists("config/synapse.dev.toml") else ""

if os.path.exists(gateway_path):
    local_resource(
        "build-synapse",
        cmd="cargo build -p synapse",
        dir=gateway_path,
        deps=[
            "%s/synapse/src" % gateway_path,
            "%s/crates" % gateway_path,
            "%s/Cargo.toml" % gateway_path,
        ],
        labels=["synapse"],
    )

    serve_cmd = "cargo run -p synapse"
    if config:
        serve_cmd = "%s -- --config %s" % (serve_cmd, config)

    local_resource(
        "dev-synapse",
        serve_cmd=serve_cmd,
        serve_dir=gateway_path,
        resource_deps=["build-synapse"],
        readiness_probe=probe(
            http_get=http_get_action(
                path="/health",
                port=6000,
            ),
            initial_delay_secs=5,
            period_secs=5,
        ),
        labels=["synapse"],
    )
else:
    print(color.yellow("synapse not found - run services bootstrap first"))

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

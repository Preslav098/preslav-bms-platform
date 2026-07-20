#!/usr/bin/env bash

set -Eeuo pipefail

BMS_PROJECT_DIR="${BMS_PROJECT_DIR:-/var/www/preslav-bms-platform}"
FLEET_PROJECT_DIR="${FLEET_PROJECT_DIR:-/var/www/fleet-management}"
SOURCE_IMAGE="${SOURCE_IMAGE:-preslav-fleet-manager:bms}"
DEPLOY_IMAGE_NAME="${DEPLOY_IMAGE_NAME:-preslav-fleet-manager}"
DEPLOY_IMAGE="${DEPLOY_IMAGE_NAME}:latest"
FLEET_CONTAINER="${FLEET_CONTAINER:-fleet-public-fleet-manager-1}"

log() {
    printf '\n\033[1;34m==> %s\033[0m\n' "$1"
}

success() {
    printf '\n\033[1;32m✔ %s\033[0m\n' "$1"
}

fail() {
    printf '\n\033[1;31m✘ %s\033[0m\n' "$1" >&2
    exit 1
}

trap 'fail "Deployment failed on line $LINENO."' ERR

command -v docker >/dev/null 2>&1 || fail "Docker is not installed or is not in PATH."

docker info >/dev/null 2>&1 || fail "Docker is not available. Start Docker or run with a user that has Docker access."

[[ -d "$BMS_PROJECT_DIR" ]] || fail "BMS project directory not found: $BMS_PROJECT_DIR"
[[ -x "$BMS_PROJECT_DIR/build-bms.sh" ]] || fail "Missing executable build script: $BMS_PROJECT_DIR/build-bms.sh"
[[ -d "$FLEET_PROJECT_DIR" ]] || fail "Fleet Management directory not found: $FLEET_PROJECT_DIR"
[[ -x "$FLEET_PROJECT_DIR/deploy/deploy-public.sh" ]] || fail "Missing executable deployment script: $FLEET_PROJECT_DIR/deploy/deploy-public.sh"

log "Building Preslav BMS image"
cd "$BMS_PROJECT_DIR"
./build-bms.sh

docker image inspect "$SOURCE_IMAGE" >/dev/null 2>&1 || fail "Build completed, but image was not found: $SOURCE_IMAGE"

log "Tagging $SOURCE_IMAGE as $DEPLOY_IMAGE"
docker tag "$SOURCE_IMAGE" "$DEPLOY_IMAGE"

log "Configuring device ingress"
FLEET_PROJECT_DIR="$FLEET_PROJECT_DIR" source "$BMS_PROJECT_DIR/scripts/configure-device-ingress.sh"

log "Stopping current Fleet Manager deployment"
cd "$FLEET_PROJECT_DIR"
export DOCKER_HUB_IMAGE="$DEPLOY_IMAGE_NAME"
./deploy/deploy-public.sh down

log "Starting Fleet Manager with $DEPLOY_IMAGE"
./deploy/deploy-public.sh up

log "Waiting for Fleet Manager container"
for _ in {1..30}; do
    if docker ps --format '{{.Names}}' | grep -qx "$FLEET_CONTAINER"; then
        break
    fi
    sleep 2
done

docker ps --format '{{.Names}}' | grep -qx "$FLEET_CONTAINER" \
    || fail "Container did not start: $FLEET_CONTAINER"

log "Running containers"
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}' \
    | grep -E "NAMES|${FLEET_CONTAINER}" || true

RUNNING_IMAGE="$(docker inspect --format '{{.Config.Image}}' "$FLEET_CONTAINER")"
[[ "$RUNNING_IMAGE" == "$DEPLOY_IMAGE" ]] \
    || fail "Fleet Manager started with '$RUNNING_IMAGE' instead of '$DEPLOY_IMAGE'."

success "Preslav BMS was built and deployed successfully."
printf '\nOpen Fleet Manager and perform a hard refresh: Ctrl + Shift + R\n'
printf 'Follow logs with:\n  docker logs -f %s\n\n' "$FLEET_CONTAINER"

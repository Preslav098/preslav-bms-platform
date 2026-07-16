#!/usr/bin/env bash

set -euo pipefail

FLEET_DIR="/var/www/fleet-management"
TEMPLATE_DIR="/var/www/preslav-bms-platform"
CUSTOMIZATION_FILE="$TEMPLATE_DIR/customization.json"
IMAGE_NAME="preslav-fleet-manager:bms"
TEMPLATE_NAME="preslav-bms"

if [ ! -d "$FLEET_DIR" ]; then
    echo "Fleet Manager directory not found: $FLEET_DIR"
    exit 1
fi

if [ ! -d "$TEMPLATE_DIR/templates/$TEMPLATE_NAME" ]; then
    echo "Template directory not found:"
    echo "$TEMPLATE_DIR/templates/$TEMPLATE_NAME"
    exit 1
fi

if [ ! -d "$TEMPLATE_DIR/contracts" ]; then
    echo "Contracts directory not found:"
    echo "$TEMPLATE_DIR/contracts"
    exit 1
fi

if [ ! -f "$CUSTOMIZATION_FILE" ]; then
    echo "Customization file not found:"
    echo "$CUSTOMIZATION_FILE"
    exit 1
fi

OVERRIDES_JSON_B64="$(
    base64 -w 0 "$CUSTOMIZATION_FILE"
)"

BUILD_COMMIT="$(
    git -C "$FLEET_DIR" rev-parse --short HEAD 2>/dev/null || echo "local"
)"

echo "============================================"
echo "Building Preslav BMS Fleet Manager image"
echo "============================================"
echo "Fleet repository: $FLEET_DIR"
echo "Template source:  $TEMPLATE_DIR"
echo "Template name:    $TEMPLATE_NAME"
echo "Docker image:     $IMAGE_NAME"
echo "Build commit:     $BUILD_COMMIT"
echo

cd "$FLEET_DIR"

DOCKER_BUILDKIT=1 docker build \
    -f deploy/docker/Dockerfile.public \
    --target runtime-bm \
    --build-context "template-source=$TEMPLATE_DIR" \
    --build-arg "TEMPLATE=$TEMPLATE_NAME" \
    --build-arg "OVERRIDES_JSON_B64=$OVERRIDES_JSON_B64" \
    --build-arg "BUILD_COMMIT=$BUILD_COMMIT" \
    -t "$IMAGE_NAME" \
    .

echo
echo "============================================"
echo "Build completed successfully"
echo "============================================"
echo "Created image: $IMAGE_NAME"
echo

docker image inspect "$IMAGE_NAME" \
    --format 'Image ID: {{.Id}}'
#!/bin/bash

set -e

echo "=========================================="
echo " Switching to official Shelly image"
echo "=========================================="

BMS_PATH="/var/www/preslav-bms-platform"
FLEET_PATH="/var/www/fleet-management"

FLEET_PROJECT_DIR="$FLEET_PATH" source "$BMS_PATH/scripts/configure-device-ingress.sh"

cd "$FLEET_PATH"

echo ""
echo "Stopping Fleet Manager..."
./deploy/deploy-public.sh down

echo ""
echo "Using official Shelly image..."

export DOCKER_HUB_IMAGE="shellygroup/fleet-management"

echo ""
echo "Starting Fleet Manager..."
./deploy/deploy-public.sh up

echo ""
echo "=========================================="
echo " Running containers"
echo "=========================================="

docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"

echo ""
echo "=========================================="
echo " Fleet Manager image"
echo "=========================================="

docker inspect fleet-public-fleet-manager-1 \
--format='{{.Config.Image}}'

echo ""
echo "Done!"
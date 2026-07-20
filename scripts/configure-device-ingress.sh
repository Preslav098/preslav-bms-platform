#!/usr/bin/env bash

# Configure Fleet Manager device-ingress values without hardcoding an IP.
# This file may be sourced by deployment scripts or executed directly.

set -Eeuo pipefail

FLEET_PROJECT_DIR="${FLEET_PROJECT_DIR:-/var/www/fleet-management}"

log_ingress() {
    printf '\n\033[1;34m==> %s\033[0m\n' "$1"
}

fail_ingress() {
    printf '\n\033[1;31m✘ %s\033[0m\n' "$1" >&2
    return 1 2>/dev/null || exit 1
}

read_env_value() {
    local file="$1"
    local key="$2"
    [[ -f "$file" ]] || return 0
    awk -F= -v key="$key" '$1 == key && length($2) > 0 {value=substr($0, index($0,"=")+1)} END {print value}' "$file"
}

upsert_env_value() {
    local file="$1"
    local key="$2"
    local value="$3"
    local directory temp

    directory="$(dirname "$file")"
    mkdir -p "$directory"
    temp="$(mktemp "${file}.XXXXXX")"

    if [[ -f "$file" ]]; then
        awk -F= -v key="$key" '$1 != key {print}' "$file" > "$temp"
    fi

    printf '%s=%s\n' "$key" "$value" >> "$temp"
    chmod --reference="$file" "$temp" 2>/dev/null || chmod 600 "$temp"
    mv "$temp" "$file"
}

detect_public_host() {
    local candidate=""

    # Explicit overrides always win. A DNS name is preferred for stable deployments.
    if [[ -n "${FM_PUBLIC_HOST:-}" ]]; then
        printf '%s\n' "$FM_PUBLIC_HOST"
        return 0
    fi

    if [[ -n "${FLEET_PUBLIC_HOST:-}" ]]; then
        printf '%s\n' "$FLEET_PUBLIC_HOST"
        return 0
    fi

    # Use the source address selected by the host's default route.
    if command -v ip >/dev/null 2>&1; then
        candidate="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for (i=1; i<=NF; i++) if ($i == "src") {print $(i+1); exit}}')"
    fi

    # Fallback for systems where route probing is unavailable.
    if [[ -z "$candidate" ]] && command -v hostname >/dev/null 2>&1; then
        candidate="$(hostname -I 2>/dev/null | tr ' ' '\n' | awk '!/^127\./ && /^[0-9]+\./ {print; exit}')"
    fi

    [[ -n "$candidate" ]] || fail_ingress "Could not detect the Fleet Manager host. Set FM_PUBLIC_HOST to an IP address or DNS name."
    printf '%s\n' "$candidate"
}

configure_device_ingress() {
    local compose_env root_env public_host public_ws_url pepper
    compose_env="$FLEET_PROJECT_DIR/deploy/compose/.env"
    root_env="$FLEET_PROJECT_DIR/.env"

    [[ -d "$FLEET_PROJECT_DIR" ]] || fail_ingress "Fleet Management directory not found: $FLEET_PROJECT_DIR"

    public_host="$(detect_public_host)"
    public_ws_url="${FM_DEVICE_INGRESS_PUBLIC_WS_BASE_URL:-wss://${public_host}/shelly}"

    pepper="${FM_DEVICE_INGRESS_TOKEN_PEPPER:-}"
    if [[ -z "$pepper" ]]; then
        pepper="$(read_env_value "$compose_env" FM_DEVICE_INGRESS_TOKEN_PEPPER)"
    fi
    if [[ -z "$pepper" ]]; then
        pepper="$(read_env_value "$root_env" FM_DEVICE_INGRESS_TOKEN_PEPPER)"
    fi
    if [[ -z "$pepper" ]]; then
        command -v openssl >/dev/null 2>&1 || fail_ingress "openssl is required to generate FM_DEVICE_INGRESS_TOKEN_PEPPER."
        pepper="$(openssl rand -hex 32)"
    fi

    # Remove duplicate definitions and write exactly one current value to both
    # locations used by Fleet Manager deployments.
    upsert_env_value "$root_env" FM_DEVICE_INGRESS_TOKEN_PEPPER "$pepper"
    upsert_env_value "$root_env" FM_DEVICE_INGRESS_PUBLIC_WS_BASE_URL "$public_ws_url"
    upsert_env_value "$compose_env" FM_DEVICE_INGRESS_TOKEN_PEPPER "$pepper"
    upsert_env_value "$compose_env" FM_DEVICE_INGRESS_PUBLIC_WS_BASE_URL "$public_ws_url"

    # Compose interpolation happens from the current process environment, so
    # export the values before deploy-public.sh creates the container.
    export FM_DEVICE_INGRESS_TOKEN_PEPPER="$pepper"
    export FM_DEVICE_INGRESS_PUBLIC_WS_BASE_URL="$public_ws_url"

    log_ingress "Device ingress configured automatically"
    printf '  Public host: %s\n' "$public_host"
    printf '  WebSocket:   %s\n' "$public_ws_url"
    printf '  Token key:   configured (%s characters)\n' "${#pepper}"
}

configure_device_ingress

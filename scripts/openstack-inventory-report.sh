
#!/usr/bin/env bash

# OpenStack Cloud Inventory Report
# Read-only resource inventory collection
# Portfolio example — lab validation pending

set -uo pipefail

OUTPUT_DIR="${1:-./reports}"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
REPORT_DIR="${OUTPUT_DIR}/inventory-${TIMESTAMP}"

echo "====================================="
echo " OpenStack Cloud Inventory Report"
echo "====================================="

if ! command -v openstack >/dev/null 2>&1; then
    echo "[ERROR] OpenStackClient is not installed."
    exit 2
fi

if [[ -z "${OS_AUTH_URL:-}" ]]; then
    echo "[ERROR] OS_AUTH_URL is not configured."
    exit 2
fi

# Ensure authentication succeeds before collecting data.
if ! openstack token issue \
    -f value -c expires >/dev/null 2>&1; then
    echo "[ERROR] OpenStack authentication failed."
    exit 2
fi

# Restrict access to generated report files.
umask 077

mkdir -p "$REPORT_DIR" || exit 2

FAILED=0

collect_inventory() {
    local label="$1"
    local filename="$2"
    shift 2

    echo "[COLLECT] $label"

    if "$@" -f json > "${REPORT_DIR}/${filename}" 2>/dev/null; then
        echo "[OK] ${filename}"
    else
        echo "[FAIL] $label"
        rm -f "${REPORT_DIR}/${filename}"
        FAILED=$((FAILED + 1))
    fi
}

collect_inventory \
    "Instances" "instances.json" \
    openstack server list --long

collect_inventory \
    "Networks" "networks.json" \
    openstack network list

collect_inventory \
    "Subnets" "subnets.json" \
    openstack subnet list

collect_inventory \
    "Routers" "routers.json" \
    openstack router list

collect_inventory \
    "Images" "images.json" \
    openstack image list

collect_inventory \
    "Volumes" "volumes.json" \
    openstack volume list

collect_inventory \
    "Security Groups" "security-groups.json" \
    openstack security group list

echo
echo "====================================="
echo " Report Summary"
echo "====================================="
echo "Output directory: $REPORT_DIR"
echo "Failed collections: $FAILED"

if [[ "$FAILED" -gt 0 ]]; then
    echo "[WARNING] Inventory report is incomplete."
    exit 1
fi

echo "[OK] Inventory collection completed."
exit 0

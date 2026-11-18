
#!/usr/bin/env bash

# OpenStack Private Cloud Health Check
# Read-only operational checks
# Portfolio example — lab validation pending

set -uo pipefail

PASSED=0
FAILED=0

echo "======================================"
echo " OpenStack Private Cloud Health Check "
echo "======================================"
echo

# Check required CLI
if ! command -v openstack >/dev/null 2>&1; then
    echo "[ERROR] OpenStackClient is not installed."
    exit 2
fi

# Check authentication environment
if [[ -z "${OS_AUTH_URL:-}" ]]; then
    echo "[ERROR] OS_AUTH_URL is not configured."
    echo "Load your authorized OpenStack RC file."
    exit 2
fi

# Execute a read-only check
run_check() {
    local name="$1"
    shift

    echo "--------------------------------------"
    echo "[CHECK] $name"

    if output=$("$@" 2>&1); then
        echo "[PASS] $name"
        PASSED=$((PASSED + 1))
        echo "$output"
    else
        echo "[FAIL] $name"
        FAILED=$((FAILED + 1))
        # Avoid printing potentially sensitive CLI error details.
        echo "Command failed. Review the local environment and service logs."
    fi

    echo
}

run_check "Keystone Authentication" \
    openstack token issue -f value -c expires

run_check "Service Catalog" \
    openstack service list

run_check "Nova Compute API" \
    openstack server list

run_check "Neutron Networking API" \
    openstack network list

run_check "Glance Image API" \
    openstack image list

run_check "Cinder Block Storage API" \
    openstack volume list

echo "======================================"
echo " Health Check Summary"
echo "======================================"
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if [[ "$FAILED" -gt 0 ]]; then
    echo "[WARNING] One or more checks failed."
    exit 1
fi

echo "[OK] All API checks completed successfully."
exit 0

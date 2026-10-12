
#!/bin/sh

# GridX — MinIO bootstrap script
# Creates required buckets and provisions restricted service access.

set -eu

MINIO_URL="${MINIO_URL:-http://minio:9000}"
POLICY_DIRECTORY="${POLICY_DIRECTORY:-/workspace/init-scripts/minio}"
KYC_BUCKET="gridx-kyc"
POLICY_NAME="auth-service-kyc"

: "${MINIO_ROOT_USER:?MINIO_ROOT_USER is required}"
: "${MINIO_ROOT_PASSWORD:?MINIO_ROOT_PASSWORD is required}"

echo "Connecting to MinIO at ${MINIO_URL}"

mc alias set local "$MINIO_URL" \
  "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" >/dev/null

# Create the private KYC bucket if it does not exist.
mc mb --ignore-existing "local/${KYC_BUCKET}"
mc anonymous set none "local/${KYC_BUCKET}"

# Provision the Auth Service identity when credentials are configured.
if [ -n "${MINIO_AUTH_SERVICE_ACCESS_KEY:-}" ] &&
   [ -n "${MINIO_AUTH_SERVICE_SECRET_KEY:-}" ]; then

  POLICY_FILE="${POLICY_DIRECTORY}/${POLICY_NAME}-policy.json"

  if [ ! -f "$POLICY_FILE" ]; then
    echo "ERROR: Policy file not found: ${POLICY_FILE}" >&2
    exit 1
  fi

  # Create the policy only if it does not already exist.
  if ! mc admin policy info local "$POLICY_NAME" >/dev/null 2>&1; then
    mc admin policy create local "$POLICY_NAME" "$POLICY_FILE"
  fi

  # Create the service user only if it does not already exist.
  if ! mc admin user info local \
      "$MINIO_AUTH_SERVICE_ACCESS_KEY" >/dev/null 2>&1; then
    mc admin user add local \
      "$MINIO_AUTH_SERVICE_ACCESS_KEY" \
      "$MINIO_AUTH_SERVICE_SECRET_KEY"
  fi

  # Attach the restricted policy to the service user.
  mc admin policy attach local "$POLICY_NAME" \
    --user "$MINIO_AUTH_SERVICE_ACCESS_KEY"

  echo "Auth Service access provisioned for ${KYC_BUCKET}"
else
  echo "WARNING: Auth Service credentials are missing; user provisioning skipped."
fi

echo "MinIO initialization complete"

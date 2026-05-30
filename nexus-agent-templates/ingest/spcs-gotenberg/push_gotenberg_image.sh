#!/usr/bin/env bash
# Push gotenberg/gotenberg:8 to Snowflake Image Repository
#
# Usage:
#   ./push_gotenberg_image.sh <repository_url>
#
# Example:
#   ./push_gotenberg_image.sh myorg-myacct.registry.snowflakecomputing.com/sps_business_insight/nexus/gotenberg_repo
#
# Prerequisites:
#   - Docker running locally
#   - Snowflake CLI or docker login to registry (see README)

set -euo pipefail

REPO_URL="${1:?Usage: $0 <repository_url>}"
IMAGE_LOCAL="gotenberg/gotenberg:8"
IMAGE_REMOTE="${REPO_URL}/gotenberg:8"

echo "==> Pulling ${IMAGE_LOCAL}"
docker pull "${IMAGE_LOCAL}"

echo "==> Tagging as ${IMAGE_REMOTE}"
docker tag "${IMAGE_LOCAL}" "${IMAGE_REMOTE}"

echo "==> Logging in to Snowflake registry"
echo "    Run if not already authenticated:"
echo "    snow spcs image-registry login --database <DB> --schema <SCHEMA>"
echo "    OR: docker login ${REPO_URL%%/*}"
read -r -p "Press Enter after docker login succeeds..."

echo "==> Pushing ${IMAGE_REMOTE}"
docker push "${IMAGE_REMOTE}"

echo "==> Done. Verify with:"
echo "    SHOW IMAGE REPOSITORIES IN SCHEMA <schema>;"
echo "    Then run 02_create_service.sql"

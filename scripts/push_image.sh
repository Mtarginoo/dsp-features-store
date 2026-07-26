#!/usr/bin/env bash
#
# Builds a service image and publishes it to OCIR under two tags: the short
# SHA of the current commit, and `latest`.
#
# The SHA is what makes it possible to tell which code a VM is running, and
# to roll back by pointing at another tag instead of rebuilding from the
# older commit. `latest` exists only as a typing shortcut.
#
# Requires `docker login gru.ocir.io` beforehand, using an Auth Token as the
# password -- not the account password.
#
# Usage:
#   ./scripts/push_image.sh          # hello service
#   ./scripts/push_image.sh hello

set -euo pipefail

SERVICE="${1:-hello}"

ENV_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/local/oci.env"
[ -f "$ENV_FILE" ] && source "$ENV_FILE"

REGISTRY="${OCIR_REGISTRY:-gru.ocir.io}"
NAMESPACE="${OCIR_NAMESPACE:-grkloncxd0gh}"
PLATFORM="${OCIR_PLATFORM:-linux/amd64}"

DOCKERFILE="services/${SERVICE}/Dockerfile"
[ -f "$DOCKERFILE" ] || { echo "no Dockerfile at $DOCKERFILE" >&2; exit 1; }

# A dirty tree would produce a SHA tag naming a commit that does not match
# the image contents -- the worst kind of error, because it stays dormant
# until the day you need to trust the tag to debug something.
if [ -n "$(git status --porcelain)" ]; then
  echo "dirty tree: commit or discard before publishing" >&2
  exit 1
fi

IMAGE="${REGISTRY}/${NAMESPACE}/${SERVICE}"
SHA="$(git rev-parse --short HEAD)"

docker buildx build \
  --platform "$PLATFORM" \
  --file "$DOCKERFILE" \
  --tag "${IMAGE}:${SHA}" \
  --tag "${IMAGE}:latest" \
  --push \
  .

echo
echo "published:"
echo "  ${IMAGE}:${SHA}"
echo "  ${IMAGE}:latest"

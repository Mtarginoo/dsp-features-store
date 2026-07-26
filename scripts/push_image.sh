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

# When the repository does not exist, OCIR creates it in the root compartment
# on first push -- where the project user is not allowed to write, so the push
# fails with a bare 403. Creating it here puts it in the project compartment
# instead, and leaves the push with nothing to do but write.
: "${OCI_COMPARTMENT_ID:?set OCI_COMPARTMENT_ID or create local/oci.env}"

existing="$(oci artifacts container repository list \
  --compartment-id "$OCI_COMPARTMENT_ID" \
  --display-name "$SERVICE" \
  --query 'data.items[0].id' --raw-output 2>/dev/null || true)"

case "$existing" in
  ocid1.containerrepo.*) ;;
  *)
    echo "creating repository ${SERVICE} in the project compartment"
    oci artifacts container repository create \
      --compartment-id "$OCI_COMPARTMENT_ID" \
      --display-name "$SERVICE" \
      --query 'data.id' --raw-output >/dev/null
    ;;
esac

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

#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# skopeo-registry-cleaner.sh
# Deletes all container images older than --days days from all repositories
# in a Docker/OCI registry, using skopeo.
# ---------------------------------------------------------------------------

usage() {
    echo "Usage: $(basename "$0") --registry <URL> --days <N>" >&2
    echo "" >&2
    echo "Required parameters:" >&2
    echo "  --registry  URL of the registry (e.g. https://nuc.lan:5000)" >&2
    echo "  --days      Maximum age of images to keep, in days" >&2
    exit 1
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
REGISTRY=""
DAYS=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --registry)
            REGISTRY="${2:-}"
            shift 2
            ;;
        --days)
            DAYS="${2:-}"
            shift 2
            ;;
        --help|-h)
            usage
            ;;
        *)
            echo "Error: unknown parameter: $1" >&2
            echo "" >&2
            usage
            ;;
    esac
done

# ---------------------------------------------------------------------------
# Validate required parameters
# ---------------------------------------------------------------------------
ERRORS=0

if [[ -z "$REGISTRY" ]]; then
    echo "Error: --registry is required" >&2
    ERRORS=1
fi

if [[ -z "$DAYS" ]]; then
    echo "Error: --days is required" >&2
    ERRORS=1
elif ! [[ "$DAYS" =~ ^[0-9]+$ ]]; then
    echo "Error: --days must be a positive integer" >&2
    ERRORS=1
fi

if [[ $ERRORS -ne 0 ]]; then
    echo "" >&2
    usage
fi

# ---------------------------------------------------------------------------
# Dependency check
# ---------------------------------------------------------------------------
for cmd in skopeo curl jq date; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: required command not found: $cmd" >&2
        exit 1
    fi
done

# ---------------------------------------------------------------------------
# Derive the host:port for skopeo docker:// URIs by stripping the scheme
# ---------------------------------------------------------------------------
REGISTRY_HOST="${REGISTRY#https://}"
REGISTRY_HOST="${REGISTRY_HOST#http://}"

# ---------------------------------------------------------------------------
# Compute the deadline epoch (images created before this are deleted)
# ---------------------------------------------------------------------------
DEADLINE=$(date -d "${DAYS} days ago" +%s)
echo "Cleaning images created before: $(date -d "${DAYS} days ago" --iso-8601=seconds)"

# ---------------------------------------------------------------------------
# Fetch all repositories from the registry catalog
# Use ?n=1000 to avoid the default limit of 100
# ---------------------------------------------------------------------------
echo ""
echo "Fetching repository list from ${REGISTRY} ..."

CATALOG=$(curl -sk "${REGISTRY}/v2/_catalog?n=1000")
if [[ -z "$CATALOG" ]]; then
    echo "Error: empty response from ${REGISTRY}/v2/_catalog" >&2
    exit 1
fi

REPOS=$(echo "$CATALOG" | jq -r '.repositories[]? // empty')
if [[ -z "$REPOS" ]]; then
    echo "No repositories found."
    exit 0
fi

REPO_COUNT=$(echo "$REPOS" | wc -l)
echo "Found ${REPO_COUNT} repositor$([ "$REPO_COUNT" -eq 1 ] && echo y || echo ies)."

# ---------------------------------------------------------------------------
# Main loop: iterate repos → tags → inspect → delete if old
# ---------------------------------------------------------------------------
DELETED=0
SKIPPED=0
KEPT=0

while IFS= read -r REPO; do
    echo ""
    echo "── ${REPO}"

    TAGS_JSON=$(skopeo list-tags \
        --tls-verify=false \
        "docker://${REGISTRY_HOST}/${REPO}" 2>&1) || {
        echo "  WARN: could not list tags for ${REPO} — skipping" >&2
        continue
    }

    TAGS=$(echo "$TAGS_JSON" | jq -r '.Tags[]? // empty')
    if [[ -z "$TAGS" ]]; then
        echo "  (no tags)"
        continue
    fi

    while IFS= read -r TAG; do
        IMAGE_REF="docker://${REGISTRY_HOST}/${REPO}:${TAG}"

        INSPECT=$(skopeo inspect \
            --tls-verify=false \
            "$IMAGE_REF" 2>&1) || {
            echo "  WARN: could not inspect ${REPO}:${TAG} — skipping" >&2
            (( SKIPPED++ )) || true
            continue
        }

        CREATED=$(echo "$INSPECT" | jq -r '.Created // empty')

        if [[ -z "$CREATED" ]]; then
            echo "  WARN: no Created field for ${REPO}:${TAG} — skipping" >&2
            (( SKIPPED++ )) || true
            continue
        fi

        IMAGE_EPOCH=$(date -d "$CREATED" +%s 2>/dev/null) || {
            echo "  WARN: could not parse date '${CREATED}' for ${REPO}:${TAG} — skipping" >&2
            (( SKIPPED++ )) || true
            continue
        }

        if [[ $IMAGE_EPOCH -lt $DEADLINE ]]; then
            echo "  DELETE  ${REPO}:${TAG}  (created: ${CREATED})"
            skopeo delete \
                --tls-verify=false \
                "$IMAGE_REF" || {
                echo "  ERROR: failed to delete ${REPO}:${TAG}" >&2
                (( SKIPPED++ )) || true
                continue
            }
            (( DELETED++ )) || true
        else
            echo "  keep    ${REPO}:${TAG}  (created: ${CREATED})"
            (( KEPT++ )) || true
        fi

    done <<< "$TAGS"

done <<< "$REPOS"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "Done."
echo "  Deleted: ${DELETED}"
echo "  Kept:    ${KEPT}"
echo "  Skipped: ${SKIPPED}"

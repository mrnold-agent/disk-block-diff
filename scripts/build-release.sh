#!/usr/bin/env bash
# Build disk-block-diff binaries for publishing (helper VM, workstation, optional libnbd).
#
# Usage:
#   ./scripts/build-release.sh
#   VERSION=v0.1.0 ./scripts/build-release.sh
#   ./scripts/build-release.sh --with-libnbd   # linux amd64 + libnbd (needs libnbd-devel)
#
# Outputs under dist/:
#   disk-block-diff-linux-amd64          static (CGO_ENABLED=0); hash, diff, apply, nbd-open*
#   disk-block-diff-linux-amd64-libnbd   optional; apply -nbd-state without nbd-client
#
# * nbd-open on static build uses nbdkit + nbd-client when available; falls back to libnbd
#   only in the -libnbd artifact.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="${ROOT}/dist"
VERSION="${VERSION:-dev}"
WITH_LIBNBD=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-libnbd)
      WITH_LIBNBD=1
      shift
      ;;
    -h|--help)
      sed -n '2,14p' "$0"
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

mkdir -p "${DIST}"

LDFLAGS="-s -w"

echo "building static linux/amd64 -> ${DIST}/disk-block-diff-linux-amd64"
(
  cd "${ROOT}"
  CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags="${LDFLAGS}" \
    -o "${DIST}/disk-block-diff-linux-amd64" .
)

if [[ "${WITH_LIBNBD}" -eq 1 ]]; then
  if ! pkg-config --exists libnbd 2>/dev/null; then
    echo "libnbd not found (install libnbd-devel); skipping libnbd build" >&2
  else
    echo "building linux/amd64 with libnbd -> ${DIST}/disk-block-diff-linux-amd64-libnbd"
    (
      cd "${ROOT}"
      CGO_ENABLED=1 GOOS=linux GOARCH=amd64 \
        go build -trimpath -ldflags="${LDFLAGS}" \
        -o "${DIST}/disk-block-diff-linux-amd64-libnbd" .
    )
  fi
fi

echo ""
echo "release binaries:"
ls -lh "${DIST}"/disk-block-diff-linux-amd64*
echo ""
echo "smoke test:"
"${DIST}/disk-block-diff-linux-amd64" parse-size -size 1GiB
echo ""
echo "publish: upload dist/disk-block-diff-linux-amd64 (and -libnbd if built)"

#!/usr/bin/env bash
# Download kubeconform to ~/.cache/pre-commit-tools (no dnf/rpm). Used by pre-commit local hook.
set -euo pipefail

readonly VERSION="${KUBECONFORM_VERSION:-v0.8.0}"
readonly K8S_VERSION="${KUBECONFORM_K8S_VERSION:-1.28.0}"
readonly CACHE="${HOME}/.cache/pre-commit-tools"
readonly OS=linux
readonly ARCH="${KUBECONFORM_ARCH:-amd64}"
readonly BIN="${CACHE}/kubeconform-${VERSION}-${OS}-${ARCH}"

install_kubeconform() {
  mkdir -p "${CACHE}"
  local tmp archive="kubeconform-${OS}-${ARCH}.tar.gz"
  tmp="$(mktemp -d)"
  curl -fsSL \
    "https://github.com/yannh/kubeconform/releases/download/${VERSION}/${archive}" \
    -o "${tmp}/${archive}"
  tar -xzf "${tmp}/${archive}" -C "${tmp}"
  install -m 0755 "${tmp}/kubeconform" "${BIN}"
  rm -rf "${tmp}"
}

if [[ ! -x "${BIN}" ]]; then
  install_kubeconform
fi

for manifest in "$@"; do
  "${BIN}" \
    -kubernetes-version "${K8S_VERSION}" \
    -summary \
    -ignore-missing-schemas \
    "${manifest}"
done

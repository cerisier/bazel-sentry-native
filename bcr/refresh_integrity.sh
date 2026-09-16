#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
version="${1:-}"
registry_arg="${2:-}"

if [[ -z "${version}" || -z "${registry_arg}" || $# -ne 2 ]]; then
    echo "usage: $0 version /path/to/bazel-central-registry" >&2
    exit 2
fi

registry_root="$(cd "${registry_arg}" && pwd)"
"${script_dir}/export_module.sh" "${version}" "${registry_root}"

(
    cd "${registry_root}"
    bazel run //tools:update_integrity -- sentry_native --version "${version}"
)

cp -p \
    "${registry_root}/modules/sentry_native/${version}/source.json" \
    "${script_dir}/modules/sentry_native/${version}/source.json"

"${script_dir}/export_module.sh" "${version}" "${registry_root}"
echo "refreshed official BCR integrity values for sentry_native@${version}"

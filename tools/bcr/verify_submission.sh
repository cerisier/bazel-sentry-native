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
"${script_dir}/prepare_entry.sh" "${version}" "${registry_root}"

set +e
(
    cd "${registry_root}"
    bazel run //tools:bcr_validation -- --check "sentry_native@${version}"
)
validation_status=$?
set -e

case "${validation_status}" in
    0)
        ;;
    42)
        echo "BCR validation passed; maintainer review is expected for this contribution"
        ;;
    *)
        echo "BCR validation failed with status ${validation_status}" >&2
        exit "${validation_status}"
        ;;
esac

(
    cd "${registry_root}"
    bazel run //tools:setup_presubmit_repos -- --module "sentry_native@${version}"
)

echo "validated and materialized sentry_native@${version} with official BCR tooling"

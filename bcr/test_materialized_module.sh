#!/usr/bin/env bash
set -euo pipefail

version="${1:-}"
registry_arg="${2:-}"
bazel_version="${3:-}"

if [[ -z "${version}" || -z "${registry_arg}" || $# -gt 3 || $# -lt 2 ]]; then
    echo "usage: $0 version /path/to/bazel-central-registry [bazel-version]" >&2
    exit 2
fi

registry_root="$(cd "${registry_arg}" && pwd)"
test_root="${registry_root}/temp_test_repos/sentry_native/${version}/test_module/module_src/e2e/bcr"

if [[ ! -f "${test_root}/MODULE.bazel" ]]; then
    echo "missing materialized BCR test module; run bcr/verify_submission.sh first" >&2
    exit 1
fi

if [[ -n "${bazel_version}" ]]; then
    export USE_BAZEL_VERSION="${bazel_version}"
fi

(
    cd "${test_root}"
    bazel --nosystem_rc --nohome_rc test \
        //:crashpad_smoke_test \
        //:shared_crashpad_smoke_test
)

echo "tested materialized sentry_native@${version} consumer with Bazel ${bazel_version:-default}"

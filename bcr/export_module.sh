#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
version="${1:-}"
registry_arg="${2:-}"
module_name="sentry_native"

if [[ -z "${version}" || -z "${registry_arg}" || $# -ne 2 ]]; then
    echo "usage: $0 version /path/to/bazel-central-registry" >&2
    exit 2
fi

if [[ "${version}" == *[!A-Za-z0-9._+-]* ]]; then
    echo "invalid module version: ${version}" >&2
    exit 2
fi

registry_root="$(cd "${registry_arg}" && pwd)"
if [[ ! -f "${registry_root}/tools/bcr_validation.py" || ! -f "${registry_root}/MODULE.bazel" ]]; then
    echo "not a bazelbuild/bazel-central-registry checkout: ${registry_root}" >&2
    exit 1
fi

source_module="${script_dir}/modules/${module_name}"
source_version="${source_module}/${version}"
target_module="${registry_root}/modules/${module_name}"
target_version="${target_module}/${version}"

if [[ ! -f "${source_module}/metadata.json" || ! -d "${source_version}" ]]; then
    echo "missing staged ${module_name}@${version} under ${source_module}" >&2
    exit 1
fi

"${script_dir}/verify_release.sh" "${version}"

mkdir -p "${target_module}"

# The fork mirrors every already-published version before preparing a new one.
# This prevents an export from silently replacing or dropping BCR-owned history.
while IFS= read -r published_version; do
    published_name="$(basename "${published_version}")"
    if [[ ! -d "${source_module}/${published_name}" ]]; then
        echo "staging is missing published BCR version ${published_name}; sync it first" >&2
        exit 1
    fi
    if ! diff -ru "${published_version}" "${source_module}/${published_name}" >/dev/null; then
        echo "staging differs from published BCR version ${published_name}" >&2
        exit 1
    fi
done < <(find "${target_module}" -mindepth 1 -maxdepth 1 -type d -print | LC_ALL=C sort)

if [[ -e "${target_version}" ]]; then
    diff -ru "${source_version}" "${target_version}" >/dev/null || {
        echo "BCR checkout already contains a different ${module_name}@${version}" >&2
        exit 1
    }
else
    cp -pR "${source_version}" "${target_module}/"
fi

cp -p "${source_module}/metadata.json" "${target_module}/metadata.json"

diff -ru "${source_version}" "${target_version}" >/dev/null
cmp -s "${source_module}/metadata.json" "${target_module}/metadata.json"

echo "exported ${module_name}@${version} to ${target_module}"

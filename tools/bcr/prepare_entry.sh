#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/../.." && pwd)"
config_root="${repo_root}/.bcr"
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

target_module="${registry_root}/modules/${module_name}"
target_version="${target_module}/${version}"
release_root="${config_root}/releases/${version}"
descriptor="${release_root}/release.json"
manifest="${release_root}/overlay_files.txt"
metadata_template="${config_root}/metadata.template.json"
presubmit="${release_root}/presubmit.yml"

if [[ ! -f "${descriptor}" || ! -f "${manifest}" || \
      ! -f "${metadata_template}" || ! -f "${presubmit}" ]]; then
    echo "incomplete BCR configuration under ${config_root}" >&2
    exit 1
fi

"${script_dir}/verify_release.sh" "${version}"

command -v jq >/dev/null || {
    echo "jq is required to prepare the BCR entry" >&2
    exit 1
}

if [[ -e "${target_version}" ]]; then
    echo "${module_name}@${version} already exists in ${registry_root}" >&2
    exit 1
fi

overlay_commit="$(jq -er '.overlay_commit' "${descriptor}")"
archive_url="$(jq -er '.archive_url' "${descriptor}")"
archive_integrity="$(jq -er '.archive_integrity' "${descriptor}")"

snapshot_root="$(mktemp -d "${TMPDIR:-/tmp}/sentry-native-bcr.XXXXXX")"
trap 'rm -rf "${snapshot_root}"' EXIT

overlay_paths=()
while IFS= read -r relative_path; do
    [[ -n "${relative_path}" ]] || continue
    overlay_paths+=("${relative_path}")
done < "${manifest}"

git -C "${repo_root}" archive \
    --format=tar \
    "${overlay_commit}" \
    MODULE.bazel \
    "${overlay_paths[@]}" | tar -xf - -C "${snapshot_root}"

mkdir -p "${target_module}"
metadata_tmp="${target_module}/metadata.json.tmp"
if [[ -f "${target_module}/metadata.json" ]]; then
    jq -s '.[0] * .[1]' \
        "${target_module}/metadata.json" \
        "${metadata_template}" > "${metadata_tmp}"
else
    jq '. + {versions: [], yanked_versions: {}}' \
        "${metadata_template}" > "${metadata_tmp}"
fi
mv "${metadata_tmp}" "${target_module}/metadata.json"

mkdir -p "${target_version}/overlay"
cp -p "${snapshot_root}/MODULE.bazel" "${target_version}/MODULE.bazel"
cp -p "${presubmit}" "${target_version}/presubmit.yml"

for relative_path in "${overlay_paths[@]}"; do
    destination="${target_version}/overlay/${relative_path}"
    mkdir -p "$(dirname "${destination}")"
    cp -p "${snapshot_root}/${relative_path}" "${destination}"
done

jq -n \
    --arg integrity "${archive_integrity}" \
    --arg url "${archive_url}" \
    '{integrity: $integrity, url: $url}' > "${target_version}/source.json"

(
    cd "${registry_root}"
    bazel run //tools:update_integrity -- "${module_name}" --version "${version}"
)

[[ "$(jq -er '.url' "${target_version}/source.json")" == "${archive_url}" ]] || {
    echo "generated source URL does not match ${descriptor}" >&2
    exit 1
}

[[ "$(jq -er '.integrity' "${target_version}/source.json")" == "${archive_integrity}" ]] || {
    echo "downloaded archive does not match the pinned release integrity" >&2
    exit 1
}

jq -e --arg version "${version}" '.versions | index($version) != null' \
    "${target_module}/metadata.json" >/dev/null || {
    echo "generated metadata does not contain ${version}" >&2
    exit 1
}

diff -u \
    <(LC_ALL=C sort "${manifest}") \
    <(find "${target_version}/overlay" -type f | sed "s#^${target_version}/overlay/##" | LC_ALL=C sort)

cmp -s "${snapshot_root}/MODULE.bazel" "${target_version}/MODULE.bazel"
for relative_path in "${overlay_paths[@]}"; do
    cmp -s \
        "${snapshot_root}/${relative_path}" \
        "${target_version}/overlay/${relative_path}"
done

echo "prepared ${module_name}@${version} in ${target_module}"

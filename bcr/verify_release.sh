#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
version="${1:-}"

if [[ -z "${version}" || "${version}" == *[!A-Za-z0-9._+-]* || $# -ne 1 ]]; then
    echo "usage: $0 version" >&2
    exit 2
fi

descriptor="${script_dir}/releases/${version}.json"
source_json="${script_dir}/modules/sentry_native/${version}/source.json"

if [[ ! -f "${descriptor}" || ! -f "${source_json}" ]]; then
    echo "missing release descriptor or staged source.json for ${version}" >&2
    exit 1
fi

command -v jq >/dev/null || {
    echo "jq is required to verify release metadata" >&2
    exit 1
}

descriptor_version="$(jq -er '.module_version' "${descriptor}")"
upstream_tag="$(jq -er '.upstream_tag' "${descriptor}")"
upstream_commit="$(jq -er '.upstream_commit' "${descriptor}")"
archive_url="$(jq -er '.archive_url' "${descriptor}")"
archive_integrity="$(jq -er '.archive_integrity' "${descriptor}")"

[[ "${descriptor_version}" == "${version}" ]] || {
    echo "release descriptor version mismatch: ${descriptor_version}" >&2
    exit 1
}

resolved_tag="$(git -C "${repo_root}" rev-parse "${upstream_tag}^{commit}")"
[[ "${resolved_tag}" == "${upstream_commit}" ]] || {
    echo "upstream tag ${upstream_tag} resolves to ${resolved_tag}, expected ${upstream_commit}" >&2
    exit 1
}

git -C "${repo_root}" merge-base --is-ancestor "${upstream_commit}" HEAD || {
    echo "HEAD does not descend from upstream ${upstream_tag} (${upstream_commit})" >&2
    exit 1
}

git -C "${repo_root}" diff --quiet "${upstream_commit}" -- .gitmodules external || {
    echo "the release branch changes upstream submodule declarations or gitlinks" >&2
    exit 1
}

if git -C "${repo_root}" submodule status --recursive | grep -Eq '^[+-U]'; then
    echo "one or more submodules are not at the superproject-pinned revision" >&2
    exit 1
fi

[[ "$(jq -er '.url' "${source_json}")" == "${archive_url}" ]] || {
    echo "source.json URL does not match the release descriptor" >&2
    exit 1
}

[[ "$(jq -er '.integrity' "${source_json}")" == "${archive_integrity}" ]] || {
    echo "source.json integrity does not match the release descriptor" >&2
    exit 1
}

"${script_dir}/sync_overlay.sh" --check "${version}"
echo "verified sentry_native@${version} release provenance"

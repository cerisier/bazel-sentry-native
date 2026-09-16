#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/../.." && pwd)"
config_root="${repo_root}/.bcr"
version="${1:-}"

if [[ -z "${version}" || "${version}" == *[!A-Za-z0-9._+-]* || $# -ne 1 ]]; then
    echo "usage: $0 version" >&2
    exit 2
fi

release_root="${config_root}/releases/${version}"
descriptor="${release_root}/release.json"
manifest="${release_root}/overlay_files.txt"

if [[ ! -f "${descriptor}" || ! -f "${manifest}" ]]; then
    echo "missing release descriptor or overlay manifest for ${version}" >&2
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
archive_sha256="$(jq -er '.archive_sha256 | select(test("^[0-9a-f]{64}$"))' "${descriptor}")"
archive_size="$(jq -er '.archive_size | select(type == "number" and . > 0)' "${descriptor}")"
overlay_commit="$(jq -er '.overlay_commit | select(test("^[0-9a-f]{40}$"))' "${descriptor}")"

[[ "${descriptor_version}" == "${version}" ]] || {
    echo "release descriptor version mismatch: ${descriptor_version}" >&2
    exit 1
}

resolved_tag="$(git -C "${repo_root}" rev-parse "${upstream_tag}^{commit}")"
[[ "${resolved_tag}" == "${upstream_commit}" ]] || {
    echo "upstream tag ${upstream_tag} resolves to ${resolved_tag}, expected ${upstream_commit}" >&2
    exit 1
}

resolved_overlay="$(git -C "${repo_root}" rev-parse "${overlay_commit}^{commit}")"
[[ "${resolved_overlay}" == "${overlay_commit}" ]] || {
    echo "overlay commit does not resolve exactly: ${overlay_commit}" >&2
    exit 1
}

git -C "${repo_root}" merge-base --is-ancestor "${upstream_commit}" "${overlay_commit}" || {
    echo "overlay commit does not descend from upstream ${upstream_tag}" >&2
    exit 1
}

git -C "${repo_root}" merge-base --is-ancestor "${overlay_commit}" HEAD || {
    echo "HEAD does not descend from overlay commit ${overlay_commit}" >&2
    exit 1
}

git -C "${repo_root}" diff --quiet "${upstream_commit}" "${overlay_commit}" -- .gitmodules external || {
    echo "the overlay commit changes upstream submodule declarations or gitlinks" >&2
    exit 1
}

if git -C "${repo_root}" submodule status --recursive | grep -Eq '^[+-U]'; then
    echo "one or more submodules are not at the superproject-pinned revision" >&2
    exit 1
fi

case "${archive_url}" in
    "https://github.com/getsentry/sentry-native/releases/download/${upstream_tag}/"*)
        ;;
    *)
        echo "release descriptor does not use the official getsentry release asset" >&2
        exit 1
        ;;
esac

[[ "${archive_integrity}" == sha256-* && -n "${archive_sha256}" && -n "${archive_size}" ]] || {
    echo "incomplete archive identity in ${descriptor}" >&2
    exit 1
}

LC_ALL=C sort -c -u "${manifest}" || {
    echo "overlay manifest must be sorted and contain no duplicates" >&2
    exit 1
}

manifest_count=0
while IFS= read -r relative_path; do
    [[ -n "${relative_path}" ]] || continue
    case "${relative_path}" in
        /*|.|..|../*|*/../*|*/..|MODULE.bazel)
            echo "invalid overlay path: ${relative_path}" >&2
            exit 1
            ;;
    esac

    [[ "$(git -C "${repo_root}" cat-file -t "${overlay_commit}:${relative_path}" 2>/dev/null)" == "blob" ]] || {
        echo "overlay path is not a file at ${overlay_commit}: ${relative_path}" >&2
        exit 1
    }

    git -C "${repo_root}" diff --quiet "${overlay_commit}" -- "${relative_path}" || {
        echo "canonical overlay file changed after ${overlay_commit}: ${relative_path}" >&2
        echo "commit the release overlay, then update overlay_commit" >&2
        exit 1
    }
    manifest_count=$((manifest_count + 1))
done < "${manifest}"

git -C "${repo_root}" diff --quiet "${overlay_commit}" -- MODULE.bazel || {
    echo "MODULE.bazel changed after overlay commit ${overlay_commit}" >&2
    echo "commit the release overlay, then update overlay_commit" >&2
    exit 1
}

module_version="$(git -C "${repo_root}" show "${overlay_commit}:MODULE.bazel" | sed -n 's/^[[:space:]]*version[[:space:]]*=[[:space:]]*"\([^"]*\)"[[:space:]]*,[[:space:]]*$/\1/p' | head -n 1)"
[[ "${module_version}" == "${version}" ]] || {
    echo "MODULE.bazel at ${overlay_commit} has version ${module_version}, expected ${version}" >&2
    exit 1
}

echo "verified sentry_native@${version}: ${manifest_count} files pinned at ${overlay_commit}"

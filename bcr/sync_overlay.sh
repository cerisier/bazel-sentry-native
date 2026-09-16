#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
manifest="${script_dir}/overlay_files.txt"

usage() {
    echo "usage: $0 [--check] [version]" >&2
}

mode="sync"
version=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --check)
            mode="check"
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --*)
            usage
            exit 2
            ;;
        *)
            if [[ -n "${version}" ]]; then
                usage
                exit 2
            fi
            version="$1"
            ;;
    esac
    shift
done

if [[ -z "${version}" ]]; then
    version="$(sed -n 's/^[[:space:]]*version[[:space:]]*=[[:space:]]*"\([^"]*\)"[[:space:]]*,[[:space:]]*$/\1/p' "${repo_root}/MODULE.bazel" | head -n 1)"
fi

if [[ -z "${version}" || "${version}" == *[!A-Za-z0-9._+-]* ]]; then
    echo "invalid module version: ${version}" >&2
    exit 2
fi

version_root="${script_dir}/modules/sentry_native/${version}"
overlay_root="${version_root}/overlay"

if [[ ! -d "${version_root}" ]]; then
    echo "missing staged module version: ${version_root}" >&2
    exit 1
fi

check_overlay() {
    local failed=0

    if ! cmp -s "${repo_root}/MODULE.bazel" "${version_root}/MODULE.bazel"; then
        echo "stale BCR MODULE.bazel; run $0" >&2
        failed=1
    fi

    while IFS= read -r relative_path; do
        [[ -n "${relative_path}" ]] || continue
        if [[ ! -f "${overlay_root}/${relative_path}" ]] || \
            ! cmp -s "${repo_root}/${relative_path}" "${overlay_root}/${relative_path}"; then
            echo "stale overlay file: ${relative_path}; run $0" >&2
            failed=1
        fi
    done < "${manifest}"

    if ! diff -u \
        <(LC_ALL=C sort "${manifest}") \
        <(find "${overlay_root}" -type f | sed "s#^${overlay_root}/##" | LC_ALL=C sort); then
        echo "overlay contains stale or missing files; reconcile it before updating integrity" >&2
        failed=1
    fi

    return "${failed}"
}

if [[ "${mode}" == "check" ]]; then
    check_overlay
    echo "verified $(wc -l < "${manifest}" | tr -d ' ') overlay files"
    exit 0
fi

mkdir -p "${overlay_root}"
cp -p "${repo_root}/MODULE.bazel" "${version_root}/MODULE.bazel"

while IFS= read -r relative_path; do
    [[ -n "${relative_path}" ]] || continue
    destination="${overlay_root}/${relative_path}"
    mkdir -p "$(dirname "${destination}")"
    cp -p "${repo_root}/${relative_path}" "${destination}"
done < "${manifest}"

check_overlay

echo "synced $(wc -l < "${manifest}" | tr -d ' ') overlay files"

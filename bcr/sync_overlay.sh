#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
version_root="${script_dir}/modules/sentry_native/0.16.6"
overlay_root="${version_root}/overlay"
manifest="${script_dir}/overlay_files.txt"

usage() {
    echo "usage: $0 [--check]" >&2
}

mode="sync"
if [[ $# -gt 1 ]]; then
    usage
    exit 2
elif [[ $# -eq 1 ]]; then
    if [[ "$1" != "--check" ]]; then
        usage
        exit 2
    fi
    mode="check"
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

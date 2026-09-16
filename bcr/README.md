# BCR release workflow

This fork is the source of truth for the Bazel overlay and its publication
automation. The Bazel Central Registry remains the source of truth for registry
validation and presubmit assembly.

## Repository model

- `master` is the fork's canonical Bazel-enabled development branch. Its first
  published state is based on the exact official `0.16.6` tag.
- `upstream` mirrors `getsentry/sentry-native`'s `master` branch exactly and
  never carries fork-owned commits.
- Clone `master` with `--recurse-submodules`. All Bazel-owned files live
  in the superproject; no overlay file is stored below a submodule gitlink.
- Canonical editable files live at their normal checkout paths. The files under
  `bcr/modules/sentry_native/<version>/overlay` are generated publication
  copies, not a second source of truth.
- BCR always downloads the official `getsentry` release asset. It never fetches
  a fork archive or this branch.

For a later upstream release, fast-forward `upstream` from the upstream remote,
merge the selected official release tag into `master`, update the canonical
Bazel files, and record the immutable input in
`bcr/releases/<version>.json`. Retain all already-published module versions
unchanged under `bcr/modules/sentry_native`.

## Local preparation

Initialize the checkout and verify its pinned source boundary:

```sh
git submodule update --init --recursive
./bcr/verify_release.sh 0.16.6
```

After editing a canonical overlay file, regenerate the versioned overlay and
review the diff:

```sh
./bcr/sync_overlay.sh 0.16.6
git diff -- bcr/modules/sentry_native/0.16.6
```

Clone the official registry separately. Exporting never edits the fork:

```sh
git clone https://github.com/bazelbuild/bazel-central-registry.git ../bazel-central-registry
./bcr/export_module.sh 0.16.6 ../bazel-central-registry
```

When the archive or overlay changes, use the registry's own integrity tool and
copy only its resulting `source.json` back into staging:

```sh
./bcr/refresh_integrity.sh 0.16.6 ../bazel-central-registry
```

Run the official validator, materialize the same anonymous and test-module
repositories used by BCR presubmit, and exercise the materialized consumer:

```sh
./bcr/verify_submission.sh 0.16.6 ../bazel-central-registry
./bcr/test_materialized_module.sh 0.16.6 ../bazel-central-registry 9.2.0
./bcr/test_materialized_module.sh 0.16.6 ../bazel-central-registry 8.4.2
```

Exit status 42 from `bcr_validation` means the automated checks passed but a
BCR maintainer must review the new module or presubmit change. The wrapper
treats that documented state as success while still rejecting validation
failures.

## Automation and publication

`bazel-overlay.yml` checks release provenance, overlay synchronization, and the
minimal static/shared graph with Bazel 8.4.2 and 9.2.0 on Linux and macOS.
`bcr.yml` exports into a fresh official BCR checkout, runs official validation,
materializes the presubmit repositories, and tests the exact consumer.

The BCR workflow is non-publishing by default. A manual dispatch with
`publish=true` creates a branch in `cerisier/bazel-central-registry` and opens
the upstream pull request. Configure a `BCR_PUBLISH_TOKEN` repository secret
with permission to push to that fork and open a public pull request. No token
is needed for ordinary pull-request validation or dry runs.

The generic `publish-to-bcr` action is intentionally not used: its release
archive flow would publish this fork's archive, while this module's contract is
the official `getsentry` archive plus a versioned BCR overlay.

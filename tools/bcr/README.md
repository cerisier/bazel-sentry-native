# BCR release workflow

This fork owns the Bazel port and the small amount of configuration needed to
publish it. The Bazel Central Registry owns the generated registry entry,
validation implementation, and immutable history of published versions.

## Repository model

- `master` is the fork's canonical Bazel-enabled development branch.
- `upstream` mirrors `getsentry/sentry-native`'s `master` branch exactly.
- Canonical Bazel files live at their normal checkout paths. They are not
  duplicated under `.bcr`.
- `.bcr/releases/<version>/overlay_files.txt` explicitly selects the files
  included in that version's overlay.
- `.bcr/releases/<version>/release.json` pins the official archive and the
  exact fork commit containing that version's overlay.
- `.bcr/metadata.template.json` and each version's `presubmit.yml` are
  publication inputs. Generated metadata, `source.json`, integrity values, and
  overlay copies are written only into a BCR checkout.
- BCR downloads the official `getsentry` release asset. It never fetches an
  archive from this fork.

The pinned overlay commit avoids retaining a second copy of every file while
keeping old submissions reproducible through Git. A release descriptor is
normally added in a follow-up commit after the overlay commit exists.

## Preparing and testing an entry

Initialize the checkout and verify its release boundary:

```sh
git submodule update --init --recursive
./tools/bcr/verify_release.sh 0.16.6
```

Clone the official registry separately. Preparation modifies only that BCR
checkout:

```sh
git clone https://github.com/bazelbuild/bazel-central-registry.git ../bazel-central-registry
./tools/bcr/prepare_entry.sh 0.16.6 ../bazel-central-registry
```

`prepare_entry.sh` reads the overlay from its pinned Git commit, runs the
official BCR integrity updater, and verifies the downloaded archive against the
release descriptor. To run the complete registry validation and consumer test
instead:

```sh
./tools/bcr/verify_submission.sh 0.16.6 ../bazel-central-registry
./tools/bcr/test_materialized_module.sh 0.16.6 ../bazel-central-registry 9.2.0
./tools/bcr/test_materialized_module.sh 0.16.6 ../bazel-central-registry 8.4.2
```

Exit status 42 from `bcr_validation` means the automated checks passed but a
BCR maintainer must review the new module or presubmit change. The wrapper
treats that documented state as success while rejecting actual failures.

## Preparing a later release

1. Fast-forward `upstream` from `getsentry/sentry-native`.
2. Merge the selected official release tag into `master`.
3. Adapt and test the canonical Bazel port.
4. Add `.bcr/releases/<version>/overlay_files.txt` and `presubmit.yml`, then
   commit the complete overlay.
5. Add `.bcr/releases/<version>/release.json` in a follow-up commit. Pin
   `overlay_commit` to the preceding overlay commit and record the official
   archive identity.
6. Update the versioned presubmit configuration when the supported matrix
   changes.
7. Prepare and validate the entry in a fresh official BCR checkout.
8. Manually dispatch the BCR workflow with `publish=true`.

## Automation and publication

`bazel-overlay.yml` checks release provenance and the direct source checkout on
Linux and macOS. `bcr.yml` generates a fresh entry inside an official BCR
checkout, runs official validation, materializes the official presubmit
repositories, and tests the exact consumer. The validated `sentry_native`
directory is transferred as a workflow artifact to the publication job, so the
published bytes are the tested bytes.

The BCR workflow is non-publishing by default. A manual dispatch with
`publish=true` creates a branch in `cerisier/bazel-central-registry` and opens
the upstream pull request. Configure `BCR_PUBLISH_TOKEN` with permission to
push to that fork and open a public pull request.

The standard `bazel-contrib/publish-to-bcr` reusable workflow can use the
official upstream archive URL, but it currently requires `MODULE.bazel` to
already exist in that archive and supports patches rather than BCR overlays.
The official sentry-native archive has no `MODULE.bazel`, so this repository
uses a narrow generator around official BCR tooling until reusable-workflow
overlay support exists.

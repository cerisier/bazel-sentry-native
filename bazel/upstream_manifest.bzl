"""Pinned provenance for the sentry-native 0.16.6 BCR overlay."""

SENTRY_NATIVE_VERSION = "0.16.6"
SENTRY_NATIVE_RELEASE_ARCHIVE = "sentry-native.zip"
SENTRY_NATIVE_RELEASE_SHA256 = "d35145daaafddc50c0c87ec564acf0ba9968e67b23981e7f57c702b2dd6f2ff1"

# Full revisions remain recorded by the release's submodule metadata. These
# prefixes make overlay reviews flag an accidental source-tree replacement.
UPSTREAM_REVISIONS = {
    "benchmark": "48f5cc21",
    "breakpad": "25b6b727",
    "crashpad": "95733c1e",
    "libunwindstack": "284202fb",
}

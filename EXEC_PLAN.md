# Native Bazel Port of sentry-native

This ExecPlan is a living implementation document. Keep `Progress`, `Surprises and Discoveries`, `Decision Log`, and `Outcomes` current while executing it. A contributor should be able to implement and verify the port from this file and the pinned upstream release without relying on the conversation that created it.

## Purpose

Package `getsentry/sentry-native` as a Bazel Central Registry module implemented with native C/C++ rules. Consumers must be able to depend on `//:sentry` as a normal `cc_library`. Consumers that need a standalone shared object must be able to build `//:sentry_shared` as a `cc_shared_library`. The production graph must not invoke CMake or use `rules_foreign_cc`.

The first supported and verified release covers Linux and macOS. Windows is the next platform milestone. Android, iOS, AIX/IBM i, PlayStation, Xbox/WINGDK, Nintendo Switch, and other private or legacy platform combinations are intentionally deferred.

The development build and test matrix uses `@llvm` as a Bzlmod development dependency. No production target may load or reference `@llvm`, because development dependencies are unavailable when this module is consumed as a dependency.

## Current Status

- The public development repository is the real GitHub fork `cerisier/sentry-native`. Its canonical `master` branch contains the Bazel port and descends from the official `0.16.6` tag commit `672b86c77c1864e1c0b5e72eefadc078e30ef700`; fork branch `upstream` mirrors `getsentry/master` exactly.
- Development uses the fork checkout with upstream's recursive Git submodules. BCR separately assembles the exact official `0.16.6` release ZIP plus the versioned overlay, and the official BCR tooling verifies that boundary.
- Milestone 1 module/configuration scaffolding is implemented.
- Milestone 2 is complete for Linux x86_64/aarch64 and macOS x86_64/arm64: native `//:sentry`, explicit source manifests, vendored Linux libunwind, and the 568 applicable `none`/`inproc` unit cases. macOS arm64 runs locally; Linux arm64 runs on remote workers with `@llvm`; the other supported desktop architectures cross-build.
- Milestone 3 is implemented: linked and runtime-loaded curl modes, independently selectable zlib compression, custom backend/transport/screenshot/platform labels, optional Qt Core injection, deterministic embedded metadata, and local-loopback HTTP tests. macOS arm64 runtime, remote Linux x86_64 linked-curl loopback tests with and without gzip, and macOS/Linux cross-build checks pass. Runtime-loaded ambient curl remains an explicitly non-hermetic opt-in mode rather than a publication gate.
- Milestone 4 implementation is complete: exact vendored Breakpad client graph, public-backend integration, external client-label override, CMake source parity, and black-box static/shared crash-artifact tests. Native macOS arm64 and remote Linux x86_64 runtime pass; Linux arm64 passed in an earlier diagnostic environment but its BuildBuddy sandbox has a documented Breakpad-only recursion anomaly, so the native BCR runner remains the publication gate. macOS x86_64 cross-builds pass.
- Milestone 5 is complete: exact Crashpad foundation, util, client, snapshot, minidump, handler, Sentry adapter, public `//:crashpad_handler`, runtime data propagation, hermetic macOS MIG generation, and black-box static/shared crash-artifact tests. Native macOS arm64 and Linux arm64 runtime pass; remote Linux x86_64/aarch64 now also pass the full static/shared crash-upload fixtures with a Bazel-owned shared libcurl runtime. Linux x86_64 remote workers cross-build the complete macOS arm64 and x86_64 Sentry/handler graphs.
- Milestone 6 is complete: `//:sentry_crash`, Linux remote unwinding, exact daemon/library manifests, and real static/shared crash-artifact processing pass on native macOS arm64 and remote Linux x86_64/aarch64. macOS x86_64 cross-build and artifact inspection pass.
- Milestone 7 is complete: `//:sentry_shared` produces the deployable shared artifact and `//:sentry_shared_library` provides the rules_cc consumer edge. Static and shared compilation roots, public exports, runtime companion propagation, dynamic metadata, and isolated-consumer behavior are verified. Private implementation include roots no longer propagate to ordinary consumers.
- Milestone 8 is in progress: the root and isolated graphs are integrated, Linux/macOS runtime gates are substantially complete, and the BCR contribution is staged and registry-validated. The checked-in consumer's literal-default static/shared Crashpad tests pass with Bazel 8.4.2 and 9.2.0 on remote Linux x86_64 and with Bazel 9.2.0 on remote Linux aarch64; Bazel 8.4.2 also passes the literal defaults on native macOS arm64 using consumer-owned `@llvm`. Native static/shared processing with embedded metadata passes on remote Linux x86_64/aarch64 and native macOS arm64. A native macOS x86_64 runner and the native BCR Linux arm64 Breakpad lane remain publication gates.
- Embedded metadata now uses a native `genrule` fed by plain Skylib settings through Make variables. The earlier generator and setting-validation rules are removed, and `SENTRY_EMBED_INFO_ITEMS` is deferred.
- Compatibility ownership is simplified: supported-platform and supported-setting checks live on public/top-level entry targets, while genuinely Linux-only or macOS-only implementation targets retain their own constraints. Generic private helpers inherit incompatibility through their owning graph. The accepted-but-deferred WinHTTP, pshttp, Windows screenshot, and Crashpad stacktrace settings remain incompatible rather than silently selecting empty source sets.
- Repository/publication hardening is implemented: every Bazel-owned Breakpad/Crashpad file lives outside Git-submodule paths. All ordinary target declarations appear explicitly in the superproject's root `BUILD.bazel`; `.bzl` files retain only source manifests, pure attribute helpers, and genuine custom rule implementations. The documented public labels are unchanged, and an explicit manifest selects the 48-file BCR overlay from a pinned fork commit.
- Reproducible publication infrastructure is split between versioned `.bcr/releases/<version>/` configuration and `tools/bcr/` automation. It generates the registry entry directly in an official BCR checkout, computes integrity with official tooling, validates/materializes the entry, tests the exact consumer, and passes the validated bytes to an opt-in pull-request job. No generated registry subtree is checked into this fork.
- Upstream inspection used `getsentry/sentry-native` release `0.16.6` and current `master` commit `0d5bec47307cba89af85525d0d1bd7fbf799c8cd` on 2026-09-16.

## Progress

- [x] Inspect upstream CMake graph, public targets, source groupings, options, dependencies, platform logic, and CI.
- [x] Build representative upstream configurations with CMake and inspect the installed artifacts.
- [x] Identify an immutable source archive suitable for a BCR version.
- [x] Classify CMake knobs as Bazel targets, build settings, platform/toolchain properties, or non-applicable CMake behavior.
- [x] Establish the initial Linux/macOS scope and deferred platform order.
- [x] Approve the implementation stack and begin the first branch.
- [x] Verify the official `0.16.6` source release and anchor the implementation branch to its real upstream Git tag and recursive submodules.
- [x] Implement module/configuration scaffolding, provenance metadata, compatibility gates, and the isolated consumer module.
- [x] Implement the core `sentry` target.
- [x] Implement and verify Linux/macOS `none` and `inproc` backends.
- [x] Implement Linux/macOS transports, compression, screenshots, and integrations.
- [x] Port and verify Linux/macOS Breakpad.
- [x] Port and verify Linux/macOS Crashpad and `crashpad_handler`.
- [x] Port and verify the Linux/macOS native backend and `sentry-crash`.
- [x] Implement and verify `sentry_shared`.
- [x] Add the isolated consumer module.
- [ ] Complete the `@llvm` matrix and native Linux/macOS runtime lanes.
- [x] Prepare and validate the BCR module contribution.
- [x] Move Bazel-owned helper files and backend target declarations out of Git-submodule paths.
- [x] Replace the macOS host-MIG exception with source-built Apple MIG 138 and verify macOS arm64/x86_64 cross-builds on Linux remote workers.
- [x] Create the public fork, promote the Bazel port to its default `master`, and preserve an unmodified `upstream` mirror of `getsentry/master`.
- [x] Add deterministic release export and official-BCR verification wrappers owned by this fork.
- [x] Add Linux/macOS Bazel smoke CI plus non-publishing-by-default BCR validation and opt-in publication workflows.
- [x] Push the Bazel implementation to the public fork and pass both hosted workflows before promoting it to `master`.
- [ ] Explicitly dispatch the guarded publisher and complete the upstream BCR pull request.
- [ ] Start the separate Windows milestone.

## Scope

### Initial supported platforms

- Linux x86_64 with glibc.
- Linux aarch64 with glibc.
- macOS x86_64.
- macOS arm64.

The minimum publication bar is build-and-run verification on native Linux and macOS runners. Cross-compilation checks supplement but do not replace runtime checks.

### Next milestone

Windows x86_64 and arm64, covering MSVC first and GNU/MinGW where practical. Windows requires dedicated treatment for exports, resources, WER DLLs, `_WIN32_WINNT`, static versus dynamic CRT, and old-Windows compatibility.

### Deferred

- Android and the separate `sentry-android` JNI wrapper.
- iOS and Apple mobile toolchains.
- AIX and IBM i PASE.
- Linux armv7.
- Linux x86_64 and aarch64 with musl. Exploratory core/curl cross-builds pass, but these configurations are not part of the first supported release.
- Linux x86/32-bit if the selected development toolchain cannot provide it.
- Windows x86/32-bit and old Windows SDK/toolset combinations.
- PlayStation/Prospero.
- Xbox/WINGDK.
- Nintendo Switch.

Deferred platforms remain visible in the compatibility design and source manifest. They must not be advertised as verified by the first BCR release.

## Naming and Consumer Contract

The normal library target is `//:sentry`, not `//:sentry_static` and not `//:libsentry`.

A Bazel `cc_library` describes a linkable C/C++ dependency. The final binary or shared-library link action gathers its transitive linker inputs and selects the appropriate static or PIC archives. Encoding “static” into the public label would expose an implementation detail and suggest that the archive should already contain all transitive dependencies, which is not Bazel's normal linking model. `libsentry` would also duplicate the conventional `lib` filename prefix generated by the toolchain.

Public targets:

| Label | Rule | Contract |
| --- | --- | --- |
| `//:sentry` | `cc_library` | Normal consumer dependency; publishes `include/sentry.h`, required compile definitions, and transitive link dependencies. |
| `//:sentry_shared` | `cc_shared_library` | Explicit deployable `libsentry.so` or `libsentry.dylib`. |
| `//:sentry_shared_library` | `cc_library` wrapper | Normal `deps` edge for consumers that must load the artifact produced by `//:sentry_shared`; necessary because `cc_shared_library` does not provide `CcInfo`. |
| `//:crashpad_handler` | `cc_binary` | Crashpad runtime companion. Present only when the Crashpad packages are compatible with the target platform. |
| `//:sentry_crash` | `cc_binary` | Native-backend runtime companion on Linux and macOS. |

`//:sentry_extension_api` is also public but explicitly unstable. It publishes the private headers needed by downstream implementations selected through the custom label settings, without introducing a dependency cycle back to `//:sentry`. Ordinary consumers must use only `//:sentry`.

Later Windows targets add `//:crashpad_wer` and `//:sentry_wer` as shared libraries.

Do not merge every private archive into a monolithic static archive. When linking `//:sentry`, Bazel must propagate and gather the backend, transport, compression, and platform archives at the consuming link action. This matches Bazel semantics and the upstream static installation, which installs separate Crashpad or Breakpad component archives.

`//:sentry_shared` needs a distinct internal compilation root from `//:sentry`. Upstream uses different build definitions for static and shared builds, notably `SENTRY_BUILD_STATIC` and `SENTRY_BUILD_SHARED`. Reusing one already-compiled `cc_library` and changing only the final link action is not sufficient on every platform.

## Pinned Upstream Input

Use release `0.16.6`, not an arbitrary `master` snapshot.

The official release asset is `sentry-native.zip`:

- Size: 9,071,053 bytes.
- SHA-256: `d35145daaafddc50c0c87ec564acf0ba9968e67b23981e7f57c702b2dd6f2ff1`.
- The archive has no enclosing top-level directory, so a BCR `source.json` must not invent a `strip_prefix`.
- The archive contains the recursive dependency sources under `external/`.

Do not use GitHub's automatically generated tag archive. That archive does not contain the checked-out submodule sources needed to build Crashpad, Breakpad, libunwindstack, and other vendored components.

The source of truth for source selection, compile definitions, link options, and platform conditions remains upstream CMake. Keep Bazel source lists explicit and grouped similarly to their CMake counterparts. Avoid broad recursive globs: they conceal new upstream files and can accidentally compile tests, platform alternatives, or unused Crashpad tools.

Development happens directly in a real fork checkout at the official release tag, with recursive upstream submodules initialized. Canonical Bazel files occupy the same paths they will have after BCR applies the overlay. Each release descriptor pins the exact fork commit from which `tools/bcr/prepare_entry.sh` extracts the manifest-selected files. Official BCR materialization then proves that the release ZIP plus generated overlay produces the same module boundary. There is no custom development-time materialization rule.

At the start of each sentry-native version update, regenerate or manually audit a checked-in parity manifest containing:

- Upstream release and archive digest.
- Selected source files by Bazel target.
- CMake target from which each group was derived.
- Submodule revision associated with each vendored component.
- Relevant compile definitions and link options.
- Known intentionally excluded sources.

## Upstream Findings

### Target and artifact graph

The principal upstream target is `sentry`, aliased by CMake as `sentry::sentry`.

Representative CMake builds on macOS arm64 produced:

- Default shared Crashpad build: `libsentry.dylib`, dSYM, and `crashpad_handler`.
- Default static Crashpad build: `libsentry.a`, Crashpad component archives, and `crashpad_handler`.
- Native shared build: `libsentry.dylib`, dSYM, and `sentry-crash`.
- Breakpad static build with no transport: `libsentry.a` and `libbreakpad_client.a`.

Crashpad's private libraries are absorbed into the shared library. In static builds, component archives remain independent link inputs.

Upstream development-only targets include unit tests, JSON fuzzing, examples, benchmarks, crash reporters, early-initialization fixtures, screenshot fixtures, application-package fixtures, platform fixtures, stack-usage fixtures, and in-process stress fixtures. These are not public module targets.

### Approximate port size

- Main `src/`: about 85 C, C++, Objective-C++, and assembly sources.
- Crashpad source tree: about 721 sources in total, including many tests and tools that must not all be selected.
- Breakpad source tree: about 291 sources.
- Android libunwindstack: about 33 sources.
- Vendored libunwind tree: about 293 sources before source filtering.
- Existing unit suite: approximately 582 cases in 45 files.
- A representative default macOS Crashpad build compiled about 254 objects.
- Representative native and Breakpad builds compiled about 114 and 71 objects respectively.

This scale justifies separate reviewable layers and exact source manifests.

### Backend behavior

| Backend | Initial Linux/macOS status | Companion artifact | Notes |
| --- | --- | --- | --- |
| `none` | Required first | None | Smallest baseline; validates core API and configuration. |
| `inproc` | Required first | None | Portable in-process crash capture. |
| `breakpad` | Required | None | Native Breakpad client library graph. |
| `crashpad` | Required | `crashpad_handler` | Default desktop backend and largest porting task. |
| `native` | Required | `sentry-crash` | Linux/macOS out-of-process backend. |
| `custom` | Extension contract only | Downstream-defined | Requires an injected implementation label. |

### Transport behavior

- Upstream defaults to curl on Linux and macOS.
- Bazel's literal `auto` value is an overlay sentinel for the behavior CMake obtains from an unset cache variable. On the current Linux/macOS scope it resolves to curl; it is not passed to upstream C code as a distinct transport.
- `none` must always remain available for minimal and hermetic tests.
- `curl` linked mode adds the BCR curl library as a transitive dependency.
- `curl` header-only mode compiles against the BCR curl headers but uses upstream's runtime `dlopen` implementation. The build graph has no curl linker input, but process execution depends on an ambient compatible libcurl and is therefore not runtime-hermetic.
- Compression uses zlib.
- `custom` transport uses the public transport API and may need a narrow label-injection point if upstream internal source injection must be retained.
- WinHTTP and `pshttp` are deferred with Windows and console work.

### Screenshots and integrations

Windows screenshot capture is deferred. Linux and macOS default to no built-in screenshot implementation unless a custom implementation is injected.

Platform integration, Qt integration, WER, and downstream console integrations must not cause unconditional dependencies. Platform integration is an injected implementation of `sentry_integration_platform_new`. Qt is not a mandatory BCR dependency: the Qt integration is a private C++17 target activated only when both its bool setting and a downstream Qt Core label are supplied.

### Unwinding

- Linux uses Sentry's pruned vendored libunwind when configured to do so.
- The vendored libunwind is based on libunwind 1.8.3 but is not equivalent to simply depending on a generic BCR libunwind module.
- It builds selected local and remote variants for x86_64, x86, aarch64, and arm.
- It intentionally excludes the C++ exception ABI implementation to avoid duplicate runtime symbols.
- The native Linux backend needs the remote unwind variant.
- macOS normally uses the platform libunwind facilities.
- Android libunwindstack is deferred with Android.

Preserve the vendored Linux target first. A later migration to a system or external libunwind must be a deliberate compatibility change backed by differential tests.

### Shared-library exports

The inspected macOS library exported the public `sentry_*` API. Linux and Android use `src/exports.map` to restrict public symbols and add build-id-related link behavior. `sentry_shared` must preserve these export boundaries. Verify symbols directly with `llvm nm`, `llvm readelf`, or platform equivalents; successful linking alone is insufficient.

### Crashpad-specific risk

The macOS Crashpad build generates Mach IPC sources with Apple's `mig` tool. The implementation pins the cross-platform port of Apple's open-source MIG 138 sources, builds `migcom` with `cc_binary`, and exposes the upstream `mig.sh` unchanged through `sh_binary`. The generated parser and lexer C sources are reviewed inputs with a pinned regeneration script, so ordinary consumers do not need Bison or Flex.

The Crashpad generator runs the upstream `mig.py`, `mig_fix.py`, and `mig_gen.py` unchanged with the registered rules_python execution runtime. It derives Clang and the macOS SDK sysroot from the selected target C++ toolchain, while `mig` and `migcom` are execution-configured tools. No action discovers `xcrun`, Clang, Python, MIG, or the SDK from ambient `PATH` state. The Linux execution image must provide `/bin/bash` and the standard utilities used by upstream `mig.sh`; the script is Bash-compatible, not POSIX `sh`.

Linux and macOS are the only compatible execution platforms for the source-built MIG tools. Windows and all deferred target platforms remain analysis-incompatible until their own implementation milestones.

## Bazel Architecture

Use ordinary `cc_library`, `cc_binary`, `cc_test`, and `cc_shared_library` targets. Small Starlark helpers may centralize source lists, settings, validation, and repeated platform selections, but must not hide a foreign build invocation.

Suggested package shape:

```text
MODULE.bazel
BUILD.bazel
build_defs/
  BUILD.bazel
  validation.bzl
config/
  BUILD.bazel
platforms/
  BUILD.bazel
src/
  BUILD.bazel
  backends/
    breakpad/BUILD.bazel
    crashpad/BUILD.bazel
    inproc/BUILD.bazel
    native/BUILD.bazel
third_party/
  breakpad/...
  crashpad/...
  libunwind/...
tests/
  BUILD.bazel
e2e/bcr/
  MODULE.bazel
  BUILD.bazel
  smoke.c
tools/
  llvm/...
```

The exact layout may adapt to the upstream archive, but package boundaries should reflect ownership and CMake target boundaries. Avoid one giant root BUILD file.

Internal structure:

- `//:sentry`: directly compiles the static-use implementation; no misleading public or private `sentry_static` label is introduced.
- `_sentry_shared_impl`: compiles the implementation for `//:sentry_shared` with shared-build definitions and PIC as selected by Bazel.
- Common source-list constants: shared between the two implementation targets without sharing incorrectly compiled objects.
- Core/private libraries: common, path, process, module finder, symbolizer, unwinder, thread, transport, screenshot, and selected backend.
- Backend targets: explicit and independently buildable, even if `//:sentry` selects one through configuration.
- Runtime companions: explicit binaries; optionally included as `data` where runfiles semantics help tests, while installation/path configuration remains documented.

The target configuration, never the execution platform, controls the selected Sentry sources and behavior. Any generator or compiler-like helper uses `cfg = "exec"`.

Every platform-specific public and private target must declare `target_compatible_with`. Rules that require a platform-specific build tool must additionally constrain the execution platform through an execution group or compatible toolchain. Unsupported combinations should become incompatible during target/toolchain resolution rather than compiling the wrong source set or failing deep inside an action.

## Build Settings and CMake Knob Mapping

Defaults use `auto` where upstream chooses according to the target platform. A configuration validation target or transition-free analysis helper must fail early with a precise error for unsupported values and combinations.

### Bazel build settings

| Upstream knob | Bazel setting | Initial values or validation |
| --- | --- | --- |
| `SENTRY_BACKEND` | `//config:backend` string flag | `auto`, `crashpad`, `inproc`, `breakpad`, `native`, `none`, `custom`. Linux/macOS `auto` resolves to Crashpad. |
| `SENTRY_TRANSPORT` | `//config:transport` string flag | `auto`, `curl`, `none`, `custom` initially. WinHTTP and pshttp deferred. |
| `SENTRY_SCREENSHOT` | `//config:screenshot` string flag | `auto`, `none`, `custom` initially. Windows deferred. |
| `SENTRY_TRANSPORT_COMPRESSION` | `//config:transport_compression` bool | Enables zlib-backed request compression. |
| `SENTRY_LINK_CURL` | `//config:link_curl` string flag | `auto`, `on`, `off`; `off` uses curl headers without linking curl transitively. |
| `CRASHPAD_ENABLE_STACKTRACE` | `//config:crashpad_stacktrace` bool | Experimental Crashpad stacktrace support. |
| `SENTRY_INTEGRATION_PLATFORM` | `//config:integration_platform` bool | Include the target-platform integration. |
| `SENTRY_INTEGRATION_QT` | `//config:integration_qt` bool plus label injection | Disabled by default; fail if enabled without a Qt Core label. |
| `SENTRY_INTEGRATION_WER` | `//config:integration_wer` bool | Deferred until Windows. |
| `SENTRY_SDK_NAME` | `//config:sdk_name` string flag | Compile-time SDK name. |
| `SENTRY_SDK_VERSION` | `//config:sdk_version` string flag | Defaults to the packaged upstream version. |
| `SENTRY_HANDLER_STACK_SIZE` | `//config:handler_stack_size` int flag | Default 64, preserving upstream units and interpretation. |
| `SENTRY_BATCHER_BUFFER_COUNT` | `//config:batcher_buffer_count` int flag | Default 3; forwarded directly and assumed valid. |
| `SENTRY_THREAD_STACK_GUARANTEE_FACTOR` | Future Windows int flag | Default 10; not active on Linux/macOS. |
| `SENTRY_THREAD_STACK_GUARANTEE_AUTO_INIT` | Future Windows bool flag | Default true; not active on Linux/macOS. |
| `SENTRY_THREAD_STACK_GUARANTEE_VERBOSE_LOG` | Future Windows bool flag | Default false; not active on Linux/macOS. |
| `SENTRY_EMBED_INFO` | `//config:embed_info` bool | Enables explicit embedded build metadata. |
| `SENTRY_BUILD_PLATFORM` | `//config:build_platform_name` string flag | Optional embedded string; distinct from Bazel's actual platform constraints. |
| `SENTRY_BUILD_VARIANT` | `//config:build_variant` string flag | Optional embedded variant. |
| `SENTRY_BUILD_ID` | `//config:build_id` string flag | Explicit value, then SDK build metadata, then deterministic `unstamped`; never action-time stamping. |
| `SENTRY_EMBED_INFO_ITEMS` | Deferred | Custom embedded fields are not exposed in the initial Linux/macOS port. |
| `SENTRY_LINK_PTHREAD` | `//config:link_pthread` string flag | Prefer `auto`, with explicit `on`/`off` only for compatibility investigation. |
| `SENTRY_LIBUNWIND_SYSTEM` | Linux libunwind label override | Default to the vendored implementation; an explicit label supplies a system/external replacement. |
| `SENTRY_BREAKPAD_SYSTEM` | Breakpad label override | Default to the vendored implementation; an explicit label supplies an external replacement. |
| `CRASHPAD_ZLIB_SYSTEM` | Crashpad zlib label selection | Prefer the BCR zlib target when compatible; retain vendored selection until differential tests prove parity. |

Plain string settings are intentionally not revalidated or escaped. Callers must supply ordinary identifier/semantic-version text that is already safe in both a POSIX shell word and a C string; quotes, backslashes, control characters, and shell metacharacters are outside the supported setting contract.

For custom backend, screenshot, transport, platform integration, Qt, system curl, system Breakpad, and system libunwind use label-valued injection points or explicitly documented aliases. Do not search the host filesystem or use ambient `pkg-config` results.

### Native Bazel or toolchain concepts, not settings

| Upstream knob | Bazel representation |
| --- | --- |
| `BUILD_SHARED_LIBS`, `SENTRY_BUILD_SHARED_LIBS` | Separate `//:sentry` and `//:sentry_shared` targets. |
| `SENTRY_PIC` | Bazel C++ toolchain and linking mode; use `--force_pic` only when required by a test. |
| `SENTRY_BUILD_FORCE32` | Target CPU platform. |
| `SENTRY_BUILD_RUNTIMESTATIC` | Windows C++ toolchain feature, deferred. |
| `WITH_ASAN_OPTION`, `WITH_TSAN_OPTION` | LLVM/toolchain sanitizer features. |
| `CMAKE_SYSTEM_VERSION` / `_WIN32_WINNT` | Windows SDK/toolchain and platform contract, deferred. |
| C99, C11, and C++17 selection | Per-target C/C++ features or toolchain flags, matching upstream target requirements. |

### Explicit targets, not settings

| Upstream knob | Bazel representation |
| --- | --- |
| `SENTRY_BUILD_TESTS` | `cc_test` targets under `//tests/...`. |
| `SENTRY_BUILD_EXAMPLES` | Explicit example binaries if retained. |
| `SENTRY_BUILD_BENCHMARKS` | Explicit development-only benchmark targets. |
| Fuzzing enablement | Explicit fuzz target, development-only. |

### Not applicable to the Bazel build

- `SENTRY_ENABLE_INSTALL`.
- `CRASHPAD_ENABLE_INSTALL`.
- `CRASHPAD_ENABLE_INSTALL_DEV`.
- `SENTRY_FOLDER` IDE grouping.
- `SENTRY_CTEST_INDIVIDUAL`.

## Dependencies

Expected production module dependencies:

- `rules_cc`.
- `platforms`.
- `bazel_skylib` only if its typed build settings materially reduce custom Starlark; otherwise prefer the smaller dependency graph.
- `curl` for the linked Linux/macOS default transport.
- `zlib` for transport compression and any Crashpad configuration that uses the external zlib target.

The current implementation pins `rules_cc` `0.2.25`, `platforms` `1.1.0`, `bazel_skylib` `1.9.2`, curl `8.21.0.bcr.2`, and zlib `1.3.2`. Curl and zlib are established BCR modules with active release histories. Lower-bound testing remains a publication task; these are current verified versions, not yet claimed minimums.

Use the lowest versions that provide the features actually required by a reusable module. Test those lower bounds. Do not force downstream consumers to upgrade merely because the root development environment used newer releases.

Vendored and ported from the release archive:

- Breakpad revision `25b6b727...`.
- Crashpad revision `95733c1e...`.
- Crashpad mini_chromium revision `2f5c168f...`.
- Crashpad Linux syscall support revisions from the release archive.
- Sentry's pruned libunwind 1.8.3 source.

Other inspected submodules include benchmark `48f5cc21...` and Android libunwindstack `284202fb...`; they are development-only or deferred and must not become unconditional production dependencies.

## Development Toolchains

Declare LLVM in the root module with `dev_dependency = True`. At the time of planning, BCR exposed LLVM `0.8.21`; pin the selected version and document any later update.

All LLVM configuration belongs to the root development environment or a consuming test module. The production module graph must remain queryable when sentry-native is a non-root dependency and its own `@llvm` development dependency is absent. The checked-in `e2e/bcr` module deliberately declares its own `@llvm` development dependency to model a consumer choosing and registering a toolchain.

Prefer registering only the needed LLVM toolchain subset where the module permits it:

- Linux x86_64 glibc.
- Linux aarch64 glibc.
- macOS x86_64.
- macOS arm64.

For remote Linux runs, pair the target platform with the same-architecture execution platform: `--config=llvm_linux_x86_64` or `--config=llvm_linux_aarch64`. LLVM's generic `@llvm//:rbe_platform` alias follows the local host architecture and is not a safe cross-architecture scheduler hint.

LLVM `0.8.21` does not permit importing its `macos_sdk` extension repository as a development-only direct repository, because the extension metadata declares non-development direct dependencies. That import is unnecessary. A development-only `osx.frameworks` tag without a root `use_repo` aggregates the required framework closure into LLVM's own hermetic SDK repository; `bazel mod tidy` accepts this form and consumers do not inherit it. The current root module combines that tag with development-only registration of `@llvm//toolchain:all`. Narrow the registered toolchain subset once the LLVM module provides a supported subset contract.

LLVM `0.8.21`'s default macOS SDK projection includes only six frameworks. Crashpad's Mini Chromium sources include AppKit and ApplicationServices umbrella headers whose transitive SDK includes require a broader framework set. The root module declares that explicit closure through the development-only tag. `FontServices` is included because the projected ATS framework contains private-framework symlinks to it; declaring the framework keeps the remote input tree closed. Neither ordinary compilation nor MIG generation uses the host SDK.

`@llvm` does not prove Android, iOS, AIX, console, Linux x86/32-bit, or old Apple SDK compatibility. Those remain separate future toolchain lanes.

## Implementation Milestones

### Milestone 1: Reproducible module and configuration schema

Create `MODULE.bazel`, root packages, platform constraints, typed settings, and configuration validation. Check in the upstream parity manifest. Add the isolated `e2e/bcr` module immediately, even before it can link the final library.

Acceptance:

- `bazel query //...` succeeds in the root module.
- As a dependency, sentry-native does not expose or resolve its root-only `@llvm` development dependency. The checked-in e2e root resolves only the separate LLVM development dependency that it owns.
- Invalid backend/transport/screenshot values fail during analysis with useful messages.
- No action invokes CMake.

### Milestone 2: Core library with `none` and `inproc`

Port the common source graph and Linux/macOS platform primitives. Implement `//:sentry` with the `none` and `inproc` backends and transport `none`. Refactor only where needed to let existing unit tests depend on private implementation libraries instead of compiling duplicate sources.

Acceptance:

- A C consumer compiles and links against `//:sentry` on Linux and macOS.
- Smoke application initializes, captures a message, flushes, and shuts down.
- Relevant upstream unit tests pass.
- Static archive architecture and public symbols are inspected, not merely built.
- The same smoke test fails before the target exists or when deliberately linked without it, proving the test exercises the port.

### Milestone 3: Linux/macOS transport and integration parity

Add curl transport, linked/header-only behavior, zlib compression, custom transport hooks, platform integration, embedded metadata, and the supported configuration settings.

Acceptance:

- Curl `on`, `off`, and `auto` configurations analyze and link as documented.
- Compression-enabled and disabled artifacts have the expected zlib dependency boundary.
- A local HTTP test server observes an actual envelope from the curl transport.
- Embedded metadata is deterministic and reflects explicit settings or stamping.
- Invalid combinations have negative analysis tests.

Implementation notes:

- `transport=auto` maps to curl on Linux/macOS. `link_curl=auto` maps to a transitive `@curl//:curl` dependency.
- `link_curl=off` selects only curl headers and upstream's dynamic loader. This preserves link-time separation but is explicitly an ambient-runtime mode.
- Compression is orthogonal to transport selection and always adds zlib when enabled, matching upstream. It is valid with custom and no transport.
- Empty SDK name/version flags resolve to the packaged defaults. SDK values are public defines because consumers compile public sentry macros; injected quote, backslash, and newline characters are rejected before compiler invocation.
- Embedded metadata is generated by a hermetic Starlark action. An explicit build ID wins, semantic-version build metadata is the second choice, and the deterministic string `unstamped` replaces upstream's wall-clock default.
- Custom implementations are label flags. Missing required labels resolve to an incompatible sentinel target and fail during analysis.

### Milestone 4: Breakpad

Port the precise Breakpad client graph for Linux and macOS. Reuse upstream source groupings and assembly rules. Keep its internal library private.

Implementation notes:

- Private `//:breakpad_client` mirrors the CMake production source groups exactly: 27 compile actions on Linux and 17 on macOS. Breakpad tests and tools are not inputs.
- Linux x86_64/aarch64 always compile Breakpad's namespaced `breakpad_getcontext.S` fallback and omit `HAVE_GETCONTEXT`. This removes an impossible cross-build libc probe and avoids collisions even when libc also provides `getcontext`.
- The sole Objective-C++ source is a private rules_cc `objc_library`. CoreFoundation remains a propagated link requirement.
- The LLVM macOS SDK omits the legacy CoreServices umbrella used only for two endian helpers. A narrow overlay header maps those helpers to their equivalent CoreFoundation APIs.
- `//config:breakpad_client` defaults to the vendored target and permits an explicitly supplied compatible implementation; no `pkg-config` or host search is performed.

Acceptance:

- `//:sentry` builds and runs with backend `breakpad` on Linux and macOS.
- A crashing fixture produces the expected crash artifact.
- Artifact contents and selected sources are compared with the pinned CMake build.
- No Breakpad test/tool source enters the production graph accidentally.

### Milestone 5: Crashpad

Port mini_chromium, Crashpad util, snapshot, minidump, client, handler libraries, required tools, compression dependency, and `//:crashpad_handler`. Resolve macOS MIG generation explicitly.

Acceptance:

- `//:sentry` builds with backend `crashpad` on Linux and macOS.
- `//:crashpad_handler` is a native `cc_binary` with the expected architecture and dynamic dependencies.
- A crashing fixture launches/communicates with the handler and produces a report.
- The handler path override and colocated-handler behavior are tested.
- Linux and macOS artifacts are compared with the same release built by CMake.

### Milestone 6: Native backend

Port `sentry-crash`, minidump/platform dependencies, and Linux remote unwinding. The daemon compiles selected SDK sources under a distinct configuration, as upstream does.

Acceptance:

- `//:sentry_crash` builds and runs on Linux and macOS.
- A crashing fixture produces a report processed by the daemon.
- Linux remote unwind support uses the intended vendored source subset.
- The daemon and library dependency graphs match the CMake source manifest.

### Milestone 7: Shared library

Implement the separate shared compilation root and `//:sentry_shared`. Apply the Linux export map and platform shared-library naming. Keep backend internals private to the dynamic artifact.

Acceptance:

- Output filenames are `libsentry.so` and `libsentry.dylib`.
- A consumer links and runs against the dynamic artifact.
- Export inspection shows the intended public `sentry_*` surface and no unintended backend implementation surface.
- Dynamic dependency inspection matches the chosen transport/backend configuration.
- Both `//:sentry` and `//:sentry_shared` can coexist in the graph without configuration ambiguity.

### Milestone 8: Full Linux/macOS verification and BCR preparation

Run root-module, isolated-consumer, configuration, unit, fixture, and differential tests. Produce BCR metadata and presubmit configuration against the immutable release archive.

Acceptance:

- Root tests pass with the pinned `@llvm` toolchains.
- The isolated consumer builds static and dynamic smoke applications with its own development toolchain; no LLVM dependency or label leaks from the sentry-native production graph.
- Native Linux x86_64 and macOS arm64/x86_64 build-and-run lanes pass.
- Supported cross-targets build with LLVM where appropriate.
- BCR presubmit builds only public targets that its runners can support.
- `source.json` validates the archive digest and archive root layout.
- The module version declares an honestly tested Bazel compatibility range.

### Milestone 9: Windows follow-up

After the Linux/macOS release is stable, add Windows as a separate plan/stack. Cover MSVC and MinGW source selection, WinHTTP, Windows screenshots, resources, DLL exports, Crashpad WER, native WER, CRT linkage features, and supported `_WIN32_WINNT` values.

Do not compromise Linux/macOS abstractions to pre-implement unverified Windows behavior. Preserve obvious extension points and platform boundaries so Windows can be added without a public target rename.

## Test Strategy

### Unit and configuration tests

Port relevant upstream tests to `cc_test`. Test public behavior and configuration boundaries; avoid assertions tied to incidental internal target decomposition. Add analysis-time negative tests for unsupported settings and combinations.

### End-to-end consumer module

Create a separate module under `e2e/bcr` with:

```starlark
local_path_override(
    module_name = "sentry_native",
    path = "../..",
)
```

It must build a minimal C application against `@sentry_native//:sentry` and another against `@sentry_native//:sentry_shared`. It declares LLVM only as its own development dependency and must not access sentry-native's root-only tools. This models the BCR ownership boundary: the consumer chooses the toolchain, while the published module remains toolchain-independent.

### Differential validation

For each supported backend and linkage mode, build the exact `0.16.6` sources once with CMake and once with Bazel under equivalent settings. Compare:

- Selected source/action manifest.
- File type and target architecture.
- Public exported symbols.
- Dynamic dependencies and rpaths/install names.
- Static archive members.
- Presence and architecture of runtime companion binaries.
- Runtime report/envelope behavior.
- Negative behavior, such as invalid configuration rejection and absent handler errors.

Passing `bazel build` is necessary but not sufficient.

The upstream test `tus_placeholder_uses_raw_location` is excluded only in the compression-enabled lane: it asserts an uncompressed body representation and is not a valid assertion when gzip is intentionally enabled. All other applicable declarations remain enabled. A focused compression test inflates the emitted body and verifies its content instead.

### Initial matrix

| Platform | Linkage | Backends | Transports |
| --- | --- | --- | --- |
| Linux x86_64 glibc | `sentry`, `sentry_shared` | none, inproc, breakpad, crashpad, native | none, curl |
| Linux aarch64 glibc | `sentry`, `sentry_shared` | none, inproc, breakpad, crashpad, native where runnable | none, curl |
| macOS x86_64 | `sentry`, `sentry_shared` | none, inproc, breakpad, crashpad, native | none, curl |
| macOS arm64 | `sentry`, `sentry_shared` | none, inproc, breakpad, crashpad, native | none, curl |

Do not create a combinatorial CI explosion. Use a small smoke matrix on every change and schedule or gate the full differential matrix for release/merge validation.

## BCR Publication

Preferred long-term location: commit Bazel files upstream so release archives contain the build definition. If upstreaming is not possible, use a BCR overlay. The curl module demonstrates that substantial overlay BUILD content is possible, but an overlay makes BCR maintainers responsible for auditing every upstream source change.

The contribution needs:

- `metadata.json`.
- Version directory for `0.16.6` or the applicable BCR revision suffix.
- `MODULE.bazel` matching the extracted/overlaid source.
- `source.json` referencing the official release ZIP and its integrity.
- Overlay BUILD and `.bzl` files, or minimal patches, if upstream does not contain them.
- `presubmit.yml` with realistic public-platform coverage.
- A standalone local-path consumer test retained in the source module.

The contribution is generated, not staged in this repository. `.bcr/releases/<version>/overlay_files.txt` selects 53 canonical files and the adjacent `release.json` pins the fork commit containing them. `tools/bcr/prepare_entry.sh` extracts those files into a supplied official BCR checkout, creates the version entry, and invokes the registry's integrity updater. Generated `source.json` points at the official release ZIP, which has no `strip_prefix`, and records the BCR tool-generated SRI for the archive and every overlay file. The resulting entry has passed official `bcr_validation` checks for source integrity, metadata, module assembly, and presubmit syntax. The expected first-version maintainer-review result for `presubmit.yml` is not a validation failure.

BCR submission follows implementation and verified Linux/macOS support. Do not publish a module that merely analyzes while its default Crashpad runtime cannot produce a report.

### Repository and publication architecture

The public development repository is a real fork of `getsentry/sentry-native`, including its Git submodules. Developers initialize those submodules normally and build directly from the checkout; there is no custom repository rule or separate materialized development tree.

Git superprojects cannot track files below a submodule gitlink. Every file owned by this Bazel port must therefore live in the sentry-native superproject rather than under `external/breakpad`, `external/crashpad`, or their nested submodules. Bazel reserves `//external`, so Breakpad, Crashpad, and Sentry targets are declared explicitly in the root `BUILD.bazel` and consume sources below `external/`. Source manifests, helper sources, compatibility headers, pure attribute helpers, and custom rule implementations live under `//bazel`; no `.bzl` macro exists merely to hide ordinary target declarations. The public targets `//:sentry`, `//:sentry_shared`, `//:sentry_shared_library`, `//:crashpad_handler`, and `//:sentry_crash` remain unchanged.

The BCR module continues to fetch the official sentry-native release archive directly. The archive URL and integrity are immutable per version. The overlay is an explicit version-specific list of Bazel-owned files extracted from a pinned fork commit. Publication output exists only in the BCR checkout and ultimately in the BCR repository; this fork does not retain a duplicate `modules/sentry_native/<version>` tree.

Publication infrastructure belongs in this fork, while the validation implementation remains owned by `bazelbuild/bazel-central-registry`. The deterministic exporter writes the selected `modules/sentry_native/<version>` directory and metadata into a supplied BCR worktree without deleting or rewriting published history. The verification wrapper invokes the official BCR validation and presubmit-repository setup from that worktree, then the consumer wrapper runs the exact generated test module with Bazel 8.4.2 or 9.2.0. Do not copy or fork BCR validation code here.

The generic `bazel-contrib/publish-to-bcr` reusable workflow can point at the official `getsentry` release asset, but it currently requires `MODULE.bazel` to exist in that archive before patches are applied and does not support BCR overlays. The official sentry-native archive has no `MODULE.bazel`. Local automation therefore generates the overlay entry around official BCR tooling and opens a pull request only after an explicit manual `publish=true` dispatch. Replace this custom layer if the reusable workflow gains overlay support or upstream release archives acquire the Bazel module files.

Implementation sequence:

1. [x] Relocate all Bazel-owned files out of Git-submodule directories.
2. [x] Move Breakpad, Crashpad, and Sentry target declarations directly into the parent-owned root `BUILD.bazel`, and update private labels without changing public targets.
3. [x] Verify direct checkout builds with initialized submodules and the existing Linux/macOS test matrix.
4. [x] Separate canonical overlay inputs from generated BCR output; retain an explicit audited overlay manifest.
5. [x] Add a release descriptor containing the official archive URL, integrity, version, upstream revision, and exact fork overlay commit.
6. [x] Replace checked-in registry staging with deterministic entry generation and official-validation wrappers.
7. [x] Reproduce the contribution from the real fork plus initialized submodules, then validate the exact official-archive-plus-overlay module on Bazel 8 and 9.
8. [x] Push the prepared release branch and pass the hosted fork/BCR verification workflows.
9. [ ] Explicitly dispatch publication to create and complete the BCR pull request.

Acceptance criteria:

- `git ls-files` reports no Bazel-owned files below a Git-submodule path.
- A recursive clone of the fork builds the existing public targets without generated source-tree setup.
- The exported overlay contains exactly the audited manifest and is reproducible byte-for-byte.
- BCR `source.json` references only the official sentry-native release archive and its verified integrity.
- Official BCR validation and exact generated-consumer tests pass without local-path overrides.
- A documented release procedure can update the fork and produce the next version-specific overlay without hand-editing copied BUILD files or integrity hashes.

## Repository Branch Plan

- `master` is the canonical Bazel-enabled fork branch. Its initial history is the consolidated implementation rooted at official tag `0.16.6`.
- `upstream` is a read-only branch mirror of `getsentry/sentry-native`'s `master`. Update it only by fast-forwarding from the upstream remote.
- Future published versions merge the corresponding official upstream release tag into `master`, adapt and commit the Bazel port, then add a descriptor that pins that overlay commit. Already-published entries remain immutable in the BCR repository rather than being duplicated here.
- The earlier expanded-archive development history remains available locally as `archive/sentry-native-bazel-core-snapshot`, but it is never pushed into the fork's canonical history.
- The manual publication workflow creates `sentry_native-<version>` in `cerisier/bazel-central-registry`, based on current official BCR `main`. It never changes the sentry-native fork's `master` branch.

## Risks and Mitigations

### Crashpad graph size and platform code

Risk: incorrect source selection, unused tools entering production, undeclared generators, or duplicated platform implementations.

Mitigation: mirror CMake target groupings, maintain explicit lists, compare action manifests, and port only required handler/client components.

### macOS MIG generation

Risk: non-hermetic dependence on the host Apple SDK or inability to cross-compile.

Mitigation: pin and source-build the cross-platform Apple MIG 138 implementation, check in its reproducibly generated parser/lexer C sources, select all tools through execution or target toolchains, and declare the target SDK as an action input. Differentially compare all generated Crashpad outputs with Apple's MIG 138. Cross-build on Linux remote workers and retain native macOS CI for runtime verification.

### Build-setting combinatorics

Risk: settings create invalid or untested target combinations.

Mitigation: typed values, `auto` defaults, analysis-time validation, negative tests, and a documented tested matrix.

### Static/shared semantic mismatch

Risk: shared-build macros or exports are applied to the normal `cc_library`, or a static label falsely promises a merged archive.

Mitigation: keep `//:sentry` idiomatic and transitive; compile a separate shared implementation root and validate symbols.

### Development dependency leakage

Risk: production targets load LLVM repositories unavailable to downstream modules.

Mitigation: isolate root-only toolchain setup and continuously query/build through the independent `local_path_override` consumer.

### Unsupported-platform overclaim

Risk: generic platform selects are mistaken for tested Android, iOS, Windows, AIX, or console support.

Mitigation: make compatibility tiers explicit in documentation and metadata. Add each platform only with its dedicated toolchain and artifact/runtime acceptance tests.

## Surprises and Discoveries

- The official release ZIP contains recursive dependency sources; the normal GitHub tag archive does not.
- Static CMake installation intentionally exposes multiple component archives. Bazel's transitive link model naturally represents this and supports naming the primary target `sentry`.
- Crashpad's macOS build generates sources using `mig`, creating an execution-platform concern in an otherwise C/C++ port.
- Apple's open-source MIG 138 is portable enough to build `migcom` on Linux once the cross-platform compatibility headers are present. Its `mig.sh` driver remains unchanged and is Bash rather than strictly POSIX `sh`.
- The released MIG source depends on generated Bison/Flex C files that are not present in the source archive. The generated lexer and parser are owned by the semantic `migcom_parser` rules_cc target in the sentry-native module and consumed by the private `@apple_mig//:migcom` tool. This keeps Bison and Flex as maintainer-only regeneration tools without representing generated files as an upstream source patch.
- A rules_python `py_binary` launcher was not sufficient for remote execution because its stage-one launcher selected `/usr/bin/env python3`. Invoking the registered file-backed execution runtime directly, with its runtime files declared as action inputs, makes the unchanged Crashpad Python scripts hermetic on Linux workers. Passing Python's `-B` flag prevents bytecode-cache writes into the external runtime repository during local sandboxed execution.
- LLVM's projected ATS framework has symlinks into private `FontServices.framework`. Adding `FontServices` to the consumer-owned SDK projection closes those remote inputs; no production target depends on `@llvm`.
- Sentry's vendored libunwind is a deliberately pruned and configured implementation, not a drop-in equivalent of the generic BCR libunwind module.
- `@llvm` covers much of the open desktop matrix but cannot be the sole proof for every upstream platform.
- The upstream Android support statements and current CI/API/NDK combinations are not perfectly aligned; Android needs a fresh compatibility contract when that milestone begins.
- LLVM `0.8.21`'s module extension metadata prevents a development-only root extension usage from passing `bazel mod tidy`; development-only direct registration of `@llvm//toolchain:all` preserves consumer isolation but is broader than the preferred subset.
- Upstream unit tests derive fixture paths from `__FILE__` and expect to run from the runfiles workspace root. Changing their working directory breaks fixture discovery; Bazel's normal test working directory is already correct.
- Two of the 570 upstream unit tests require an HTTP transport (`basic_transport_thread_name` and `cache_keep`). The transport-`none` lane explicitly skips only those two and executes the remaining 568.
- The Linux build intentionally omits `SENTRY_HAVE_COPY_FILE_RANGE` for now. That selects upstream's portable fallback and avoids claiming a libc/kernel capability merely from the target OS; a future sysroot-aware setting may enable it.
- Upstream has no literal `auto` backend/transport/screenshot value. The Bazel settings use it only as a stable sentinel and translate it to the platform default before selecting sources.
- Upstream's empty embedded build ID expands to a configure-time timestamp. That is irreproducible under Bazel, so the overlay deliberately uses `unstamped` unless the caller supplies a build ID or SDK-version build metadata.
- The upstream TUS placeholder test assumes a raw request body and fails for the expected reason when compression is enabled. The compression lane skips only that assertion and adds a focused inflate-and-compare test instead.
- Supplying a Qt Core label is sufficient to express the dependency graph, but no real Qt target has yet been compiled. Qt remains optional and unverified rather than advertised as a tested integration.
- The initially connected Linux host was unusable (`ssh` authentication rejected). The current Linux acceptance evidence comes from BuildBuddy x86_64/aarch64 remote workers with explicitly paired `@llvm` target and execution platforms. An earlier container run is diagnostic history only; Docker is not part of the current build or publication workflow.
- Crashpad's nested mini_chromium, zlib, and LSS payloads are present in the official release ZIP but ignored by Crashpad's own `.gitignore`. The first Git import therefore omitted them from clean worktrees even though they remained on disk. They are now force-tracked as exact release inputs.
- Bazel's legacy execroot layout reserves the main repository's top-level `external/` path. The upstream sentry-native layout owns that same path, so actions lose their source symlinks unless root development enables sibling repository layout. BCR consumers do not have this collision because sentry-native is then an external module repository.
- The release also contains upstream Google Benchmark BUILD packages with unrelated workspace-only Python/gtest repositories. Root recursive queries explicitly exclude those development-only packages; no production target depends on them.
- Breakpad terminates a handled crash by re-raising the signal on Linux but exits with status 1 from its macOS Mach exception path. The black-box test accepts those two upstream behaviors only after independently proving the persisted fatal minidump envelope.
- One upstream unit assertion expects crash-time logging enabled globally, while the same pinned implementation deliberately disables it for macOS Breakpad to avoid deadlock in suspended threads. Only that assertion is skipped in the macOS Breakpad lane; the behavior is documented in source and crash-artifact coverage remains active.
- Crashpad's transport always brings its own curl dependency through `crashpad_util`, even when Sentry is configured with `transport=none`. Sentry transport selection and Crashpad report upload are independent graphs upstream and remain independent in Bazel.
- Crashpad's macOS snapshot graph includes seven `.proctype` files through CMake directory-level behavior. They must be explicit Bazel textual inputs; otherwise sandboxed compilation fails despite an apparently complete C/C++ manifest.
- Upstream Crashpad startup searches beside the current executable when no handler path is supplied. A normal Bazel runfiles data edge does not guarantee that adjacency, so unit tests need a declared output symlink beside the test executable. This is test-layout plumbing, not a change to SDK handler discovery.
- Crashpad's initial remote crash-fixture timeout was caused by its upstream Linux uploader finding no ambient `libcurl.so`, not by signal delivery. A private `cc_import` of BCR curl's shared artifact plus an always-linked symbol anchor gives `crashpad_handler` a declared `DT_NEEDED`, Bazel RUNPATH, and runfiles payload. Full static/shared crash uploads now pass on remote Linux x86_64 and aarch64 without a system libcurl.
- macOS x86_64 binaries execute under Rosetta, and Crashpad handler initialization/negative behavior passes, but translated Mach-exception crash delivery does not reach the upload fixture. Do not patch SDK behavior around translation; retain cross-build evidence locally and use the BCR `macos` runner for the native x86_64 runtime lane.
- Upstream's ordinary unit matrix is built with `backend=none`; running all unit cases against Linux Crashpad is not an upstream acceptance lane. Several cases intentionally initialize the SDK more than once in one process, which Crashpad rejects after its process-global handler is installed. Backend-specific crash fixtures own Crashpad validation.
- An earlier Docker Desktop diagnostic exposed `DT_UNKNOWN` directory entries for the upstream OS-release fixture, while the remote Linux worker's normal filesystem passes that case. Container filesystem behavior is not used as release evidence.
- When this module's unit target is invoked from an anonymous/BCR-style external module, Bazel compiles `__FILE__` with an `external/<canonical-name>/` prefix but places that repository beside the test's `_main` runfiles directory. Test-only file/macro prefix maps preserve upstream's relative fixture lookup in both root and external-module execution.
- rules_cc `cc_shared_library` deliberately does not provide `CcInfo`. `//:sentry_shared` therefore remains the actual deployable artifact target, while `//:sentry_shared_library` is the public `cc_library` wrapper used by ordinary consumers.
- Reusing the root checkout's sibling-repository flag in an otherwise external-only registry consumer can create remote actions whose `_main` working directory has no input-tree entry. This is not a published-module requirement: the flag exists only to resolve the root source archive's top-level `external/` collision and is not inherited by normal BCR consumers. Registry-consumer remote tests explicitly disabled it.
- LLVM's `@llvm//:rbe_platform` alias selects an execution architecture from the machine running Bazel, not from `--platforms`. On an arm64 Mac it scheduled a Linux x86_64 consumer binary on an arm64 worker: compilation succeeded, but the remote test failed with `Exec format error`. The repository configs now pair each Linux target with `@llvm//:rbe_linux_x86_64` or `@llvm//:rbe_linux_aarch64` explicitly.
- Bazel reserves the main repository label `//external` for legacy external-repository behavior and rejects a user-defined package there under Bzlmod. The superproject can track `external/BUILD.bazel` in Git, but Bazel cannot load it. Breakpad and Crashpad declarations therefore live directly in the root `BUILD.bazel` while consuming sources below `external/`.
- The official BCR `setup_presubmit_repos` flow must be run from a checkout that contains every declared dependency version. A stale local BCR checkout predated required dependency versions; reproducing against current `bazelbuild/bazel-central-registry` commit `90343df1301b2970238f37ac3b8fcb3abf8fea9a` assembled both the anonymous module and the exact `e2e/bcr` test module successfully.
- BCR overlay integrity alone does not prove the staged files still match the development tree: it can faithfully validate a stale overlay. The overlay sync tool now has a non-mutating `--check` mode so source-to-overlay drift is a required local verification before regenerating SRI values.
- Bazel 9 reports `module.compatibility_level` as a no-op scheduled for removal. The module omits that field and declares the actually tested floor `bazel_compatibility = [">=8.4.2"]`, verified with Bazel 8.4.2 and 9.2.0.
- Bazel 8 emits a `cc_library.includes` directory as `-isystem`, after the LLVM sysroot. That bypassed Crashpad's deliberate libc/SDK shadow headers: an exact BCR consumer failed because glibc's `signal.h` won and `X86_FXSR_MAGIC` was undeclared. Header-only native `cc_library` targets now expose the Linux, non-macOS, and macOS wrapper trees through `strip_include_prefix`; their virtual include roots are ordinary `-I` entries before system headers on Bazel 8 and 9. The source wrappers and their `#include_next` behavior remain upstream-identical.
- Bazel 8's `cc_shared_library` traversal did not carry the link archives of transitive `objc_library` targets into `libsentry.dylib`. Three private `cc_import` archive adapters make the Mini Chromium, Crashpad util, and Crashpad client Objective-C++ archives explicit C++ linker inputs. Bazel 8/9 native macOS arm64 static/shared crash artifacts now both pass.
- BuildBuddy's Linux arm64 remote worker can run Crashpad and native-backend process fixtures, but the Breakpad fixture enters the crash callback, recurses through a `sentry_value_get_type` assertion, and times out. An earlier container run passed the same AArch64 artifact, but is diagnostic only; BCR's native `ubuntu2004_arm64` runner remains the publication gate.
- A Bazel 8 macOS root module cannot compile rules_cc `objc_library` targets until it registers an Apple-capable C++ toolchain. The BCR e2e consumer therefore owns `@llvm` as its own development dependency and instantiates the required SDK framework closure. This is consumer test infrastructure, not a transitive production dependency from sentry-native.
- BCR anonymous test modules intentionally ignore the dependency's development dependencies. An exact anonymous Bazel 8 macOS reproduction therefore fails at Crashpad's first `objc_library` with “requires the Apple CC toolchain.” Anonymous Bazel 8 backend/default lanes are Linux-only; macOS Bazel 8 runs in `bcr_test_module`, whose root explicitly owns LLVM. Bazel 8.4.2 literal-default static/shared Crashpad artifacts pass there on native macOS arm64.
- The native backend applies GNU C language modes to part of its C source set. Compiling generated embedded metadata as another source in that mixed target leaked `-std=gnu11`/`gnu99` onto C++. The generated C++17 translation unit is now an always-linked private library, used separately by static/shared SDK roots and `sentry-crash`.
- Ordinary consumers initially inherited the implementation's `src/` and native-daemon include roots. Private header-only libraries plus rules_cc `implementation_deps` retain those compilation contexts only for SDK actions. An external-consumer action-query now contains only the public virtual include tree.
- Platform OS/CPU checks alone accidentally accepted LLVM musl platforms even though musl is deferred. Production and Crashpad targets additionally require the rules_cc libc constraint `glibc` or `macosx`; unsupported libc platforms fail during target compatibility analysis.
- The shared native consumer wrapper originally propagated only the Crashpad handler. Its configuration-selected runtime data now also carries `sentry-crash`; a configured dependency-path query proves the wrapper-to-daemon edge, and static/shared native crash fixtures pass on Linux x86_64/aarch64 and macOS arm64.
- Skylib `string_flag` and `int_flag` expose their optional `make_variable` through `TemplateVariableInfo`. A native `genrule` can consume those values by listing the settings in `toolchains`; no file-generating Starlark rule is required. Skylib's `write_file` and `expand_template` do not perform this Make-variable expansion themselves.

## Decision Log

- 2026-09-16: Pin the first port to stable release `0.16.6`; do not publish an unversioned `master` snapshot.
- 2026-09-16: Use only native C/C++ Bazel rules in the production graph; no `rules_foreign_cc` or CMake actions.
- 2026-09-16: Name the normal consumer target `//:sentry`; do not expose `sentry_static` or `libsentry` as the primary label.
- 2026-09-16: Expose `//:sentry_shared` only for a concrete deployable shared-library artifact.
- 2026-09-16: Support and verify Linux and macOS first.
- 2026-09-16: Implement Windows in the next milestone.
- 2026-09-16: Defer Android, iOS, AIX/IBM i, private consoles, and legacy platform combinations.
- 2026-09-16: Keep LLVM root-only with `dev_dependency = True`; prove consumer isolation with a separate module.
- 2026-09-16: Preserve vendored backend/unwinding implementations until differential tests justify substitution.
- 2026-09-16: Develop and test the Bazel overlay directly in a real fork branch rooted at the official release tag, with recursive upstream submodules initialized. Verify BCR assembly separately from the official release archive plus the synchronized overlay.
- 2026-09-16: Prioritize Linux when macOS blocks progress; an explicit macOS host-tool fallback was initially acceptable. This fallback was later removed by the source-built MIG 138 decision below.
- 2026-09-16: Mark unsupported target and execution platforms incompatible instead of allowing late compile/action failures.
- 2026-09-16: Check in the generated-equivalent libunwind configuration headers needed by the BCR overlay. Keep them conservative and sysroot-portable. Publish only the verified glibc contract; mark deferred musl platforms incompatible rather than treating exploratory cross-builds as support.
- 2026-09-16: Preserve upstream's batcher-buffer validation as an analysis-time integer setting constrained to 2 through 10. Superseded on 2026-09-17 by the plain-setting decision below.
- 2026-09-16: Use BCR curl `8.21.0.bcr.2` and zlib `1.3.2`; keep curl and compression dependencies conditional in the analyzed C++ graph.
- 2026-09-16: Treat `link_curl=off` as an explicitly non-hermetic runtime mode, not as a hermetic alternative to the default linked curl mode.
- 2026-09-16: Expose custom backend, transport, screenshot, platform integration, and Qt Core dependencies through label settings. Missing labels analyze as incompatible.
- 2026-09-16: Generate embedded information hermetically and use deterministic `unstamped` rather than copying upstream's configure-time clock behavior.
- 2026-09-16: For Linux Breakpad, always compile the upstream namespaced assembly `getcontext` fallback instead of probing the execution host or target libc.
- 2026-09-16: Preserve the separate Breakpad `cc_library` and let the final Bazel link action gather its objects transitively; do not merge it into `libsentry.a`.
- 2026-09-16: Enable Bazel sibling repository layout for root development because the immutable upstream archive owns a top-level `external/` directory.
- 2026-09-16: Keep upstream dependencies as real recursive Git submodules in the fork checkout. Store no Bazel-owned file under a submodule gitlink; rely on the official release ZIP's expanded dependency payload only at the BCR assembly boundary.
- 2026-09-16: Supersede the temporary `/usr/bin/xcrun mig` host-tool exception. Pin the cross-platform Apple MIG 138 sources at `f337e600741638896fb6056ce87c6479f74b89a3`, source-build `migcom`, and run the upstream `mig.sh` plus Crashpad Python scripts unchanged. Obtain Python and MIG from execution-configured toolchains/targets, and Clang plus the SDK from the selected target C++ toolchain. Checked-in parser/lexer sources remove Bison and Flex from ordinary builds. Linux remote execution is now supported; `/bin/bash` plus upstream script utilities are the only ambient execution-image contract.
- 2026-09-16: Keep `crashpad_stacktrace=true` analysis-incompatible until the separate remote-unwind/ptrace and Crashpad-libunwind graphs are implemented and verified. Do not silently reuse the local-only Sentry unwind target.
- 2026-09-16: Stage `crashpad_handler` beside tests with a Bazel-declared symlink action so upstream executable-relative discovery is tested without a host-shell copy action or an SDK source patch.
- 2026-09-16: Prefer remote Linux workers for hermetic unit and real process fixtures. Treat the BuildBuddy arm64 Breakpad recursion as runner-specific diagnostic evidence and retain the native BCR `ubuntu2004_arm64` lane as the publication gate; Crashpad and native-backend remote fixtures pass.
- 2026-09-16: Keep `//:sentry_shared` as the actual `cc_shared_library`; add `//:sentry_shared_library` solely as the CcInfo-bearing consumer wrapper required by rules_cc.
- 2026-09-16: Keep ordinary target declarations explicit in the root `BUILD.bazel`; reserve `.bzl` files for manifests, pure attribute helpers, and genuine custom rules rather than macros that only declare targets.
- 2026-09-16: Publish the tested Bazel floor 8.4.2 after exact-registry consumer builds pass with Bazel 8.4.2 and 9.2.0; omit the deprecated no-op `compatibility_level` field.
- 2026-09-16: Keep sibling repository layout as root-development configuration only. Do not require or recommend it for BCR consumers, whose sentry-native sources live in an external repository and do not collide with Bazel's legacy main-repository `external/` path.
- 2026-09-16: Define explicit `llvm_linux_x86_64` and `llvm_linux_aarch64` development configs that pair target and execution architectures. Do not use LLVM's host-derived generic RBE alias for cross-architecture remote tests.
- 2026-09-16: Preserve Crashpad's Linux runtime-loaded curl API while replacing its ambient system-library assumption with a private BCR `curl_shared` runtime. Keep `crashpad_util` header-only with respect to curl so the handler does not embed a second static curl implementation.
- 2026-09-17: Model Crashpad's libc/SDK shadow include roots with private header-only native `cc_library` targets and virtual include trees rather than `cc_library.includes`. This preserves `#include_next` precedence on Bazel 8 and 9 without a custom provider. Bazel normalizes the reserved physical `external/crashpad/...` source path in external-module topology but not in the root checkout, so a pure helper selects `external/crashpad/compat/...` for the root and `compat/...` for a consumer repository.
- 2026-09-17: Inline root-only Sentry attribute values in the root `BUILD.bazel` and remove `bazel/sentry.bzl`. Keep compatibility policy on public/top-level graph boundaries and explicit Linux-only/macOS-only targets; let generic private helpers inherit incompatibility transitively. Retain accepted values for deferred knobs and reject unsupported combinations at the public boundary.
- 2026-09-16: Wrap each private macOS `objc_library` output in a `cc_import` archive adapter so Bazel 8 `cc_shared_library` sees the Objective-C++ linker inputs; retain Objective-C++ compilation and framework ownership in the original rules.
- 2026-09-16: Make the BCR e2e module own LLVM `0.8.21` as a development dependency, including macOS SDK projection and toolchain registration. Production sentry-native targets remain independent of `@llvm`; every root consumer chooses and registers its own toolchain.
- 2026-09-16: Use rules_cc target libc constraints to publish Linux glibc plus macOS only. Defer musl and reject it at analysis until it has its own verified contract.
- 2026-09-16: Keep SDK/backend/transport/private-header dependencies behind `implementation_deps`; only `sentry.h`, SDK identity defines, and required link inputs form the ordinary public compile contract.
- 2026-09-16: Compile embedded metadata in its own C++17 library and force-link it, rather than mixing generated C++ with backend-specific C language-mode actions.
- 2026-09-16: Restrict anonymous BCR Bazel 8 backend/default tasks to Linux. Run macOS Bazel 8 from `bcr_test_module`, where the consumer can lawfully own and register its LLVM development toolchain.
- 2026-09-16: Use fork `master` as the canonical Bazel-enabled branch and fork `upstream` as the exact `getsentry/master` mirror. For subsequent releases, merge the official release tag into `master`; published version directories remain immutable in BCR itself.
- 2026-09-16: Publish from the official getsentry archive plus an overlay using fork-owned entry generation. The standard `publish-to-bcr` workflow supports arbitrary archive URLs, but not an overlaid `MODULE.bazel`; revisit it when overlay support exists.
- 2026-09-17: Generate `sentry_embedded_info.cpp` with a native `genrule` and Make variables from plain Skylib settings. Assume callers provide valid SDK identity, buffer count, platform, variant, and build-ID values; remove `c_string_flag` and `bounded_int_flag`. Defer `SENTRY_EMBED_INFO_ITEMS`. Preserve deterministic `unstamped` fallback instead of CMake's timestamp.
- 2026-09-17: Remove the Bazel-only macOS exported-symbol list. Match upstream CMake by relying on hidden compilation visibility plus `SENTRY_API` default visibility; retain the Linux version script, which upstream explicitly configures.

## Outcomes

### Milestone 1 report — module and configuration schema

Implemented the BCR-overlay scaffold directly in the fork checkout rooted at official tag `0.16.6`:

- Root `MODULE.bazel` with minimum production dependencies and LLVM `0.8.21` as `dev_dependency = True`.
- Typed backend, transport, screenshot, integration, metadata, stack-size, buffer-count, curl-link, and pthread settings.
- Linux/macOS target compatibility plus current backend/transport compatibility gates.
- Pinned release provenance in the versioned `.bcr/releases/0.16.6/release.json` descriptor.
- Independent `e2e/bcr` module using `local_path_override`.
- Initial incompatible placeholder for `//:sentry`, subsequently replaced by the Milestone 2 native `cc_library`.

Verification performed with Bazel 9.2.0:

- Root `bazel query //...`: passed.
- Isolated consumer `bazel query @sentry_native//:sentry`: passed without declaring LLVM.
- `bazel build //:sentry --//config:backend=none --//config:transport=none`: compatibility scaffold passed.
- Invalid backend value: rejected during analysis with the complete allowed-value list.
- Overlay files formatted with `buildifier`.

No build action invokes CMake.

### Milestone 2 progress report — core library, `none`, and `inproc`

Implemented:

- `//:sentry` as the public native `cc_library`, producing `libsentry.a` while leaving transitive dependency collection to consumer link actions.
- Explicit common, Unix, Linux, macOS, backend, transport, and private-header manifests derived from the release CMake graph.
- Private `//:_sentry_mpack` compilation preserving upstream's warning suppression boundary.
- Vendored `//vendor/libunwind:unwind` for Linux x86_64/aarch64, including reviewed generated-equivalent configuration headers rather than a configure action or host probe.
- Exact Linux/macOS compatibility constraints. A Windows target request fails during analysis as incompatible.
- `none` and `inproc` backend definitions, transport `none`, Linux system link inputs, public header mapping, and upstream warning/visibility options.
- A plain `batcher_buffer_count` integer setting, forwarded directly to the compile definition.
- Bazel ports of all 570 upstream unit declarations, fixtures, and fuzz regression corpus. The transport-`none` lane skips only the two HTTP-transport-specific tests.
- Public and isolated-consumer smoke applications that initialize the SDK, capture an event, and shut down.

Verification with Bazel 9.2.0 and LLVM `0.8.21`:

- macOS arm64 `none` and `inproc` static library builds: passed.
- macOS arm64 isolated consumer runtime with `inproc`/`none` transport: passed and emitted backend initialization, event capture, and shutdown logs.
- macOS arm64 upstream unit suite with `none` and `inproc`: 568 applicable tests passed in each configuration.
- macOS x86_64 cross-build: passed; `lipo` reports an x86_64 archive.
- Linux x86_64 glibc 2.28 `inproc` unit binary cross-build: passed; ELF inspection reports AMD x86-64 and `/lib64/ld-linux-x86-64.so.2`.
- Linux aarch64 glibc 2.28 `inproc` unit binary cross-build: passed; ELF inspection reports AArch64 and `/lib/ld-linux-aarch64.so.1`.
- Historical exploratory Linux x86_64/aarch64 musl `inproc` cross-builds passed, but musl remains outside the published compatibility contract and is now rejected during target analysis.
- Linux x86_64 `libsentry.a`: archive members inspected; public definitions include `sentry_init`, `sentry_capture_event`, and `sentry_close`; action summary contains 52 C++ compile actions and one archive action.
- `batcher_buffer_count` values are not revalidated by Bazel; callers are responsible for preserving upstream's 2–10 contract.
- Windows target platform: rejected during analysis as incompatible.

Linux runtime completion:

- BuildBuddy Linux arm64 remote execution with the LLVM glibc 2.28 platform passed all 568 applicable cases for both `backend=none` and `backend=inproc` from an anonymous external-module harness.
- macOS arm64 reran all 568 `none` cases after the external-runfiles normalization and remained green.
- The test-only prefix map converts Bazel's external execroot `__FILE__` prefix to the sibling repository runfiles path; fixture-based cases now pass in both root and BCR-style execution.

Linux armv7 remains unimplemented and incompatible; it requires its libunwind source/assembly manifest and a runnable validation lane.

### Milestone 3 report — transports, compression, and integrations

Implemented:

- BCR curl transport with `auto`, linked, and runtime-loaded modes. Linked mode propagates the full curl graph; runtime-loaded mode propagates only the curl headers and uses upstream's `dlopen` path.
- Optional zlib transport compression independent of transport selection.
- Custom backend, transport, screenshot, and platform-integration label injection, plus the unstable headers-only `//:sentry_extension_api` dependency used to implement those contracts.
- Optional Qt integration as a private C++17 target with a required injected Qt Core label.
- Plain SDK identity settings, pthread selection, and deterministic embedded metadata generation. Custom metadata fields are deferred.
- A hermetic C loopback HTTP server that receives a real Sentry envelope, plus focused gzip decompression/content validation.

Verification with Bazel 9.2.0 and LLVM `0.8.21`:

- macOS arm64 full unit suite: 568 applicable tests passed with transport none; all 570 passed with linked curl. The compression lane excludes only the raw-body TUS assertion and its focused gzip test passed.
- macOS arm64 loopback HTTP runtime: passed with linked curl uncompressed, linked curl compressed, and runtime-loaded host libcurl.
- Custom backend/transport/screenshot/platform-integration aggregate runtime: passed; the injected integration's context was observed in `before_send`.
- macOS x86_64 curl+compression cross-build: passed; output inspected as Mach-O x86_64.
- Linux x86_64 and aarch64 glibc 2.28 curl+compression cross-builds: passed; outputs inspected as ELF AMD x86-64 and AArch64. The x86_64 dynamic section contains only the expected system loader/libraries because curl, zlib, and TLS are linked statically.
- A historical exploratory Linux x86_64 musl curl+compression cross-build passed and was inspected as statically linked. It is not release evidence; musl remains deferred and analysis-incompatible.
- Isolated BCR-style consumer without LLVM: resolved, linked, and ran against `transport=auto`.
- Action inspection: curl-linked/compressed/pthread-on includes curl, zlib, and `-lpthread`; curl-runtime/compression-off/pthread-off includes none of those linker inputs.
- Invalid SDK semantic version and embedded item syntax fail during analysis. Missing custom and Qt labels, deferred Windows, and other unsupported combinations fail as incompatible.
- Embedded object strings were inspected and matched the explicit platform, build ID, variant, compilation mode, and custom items. Version build metadata was also verified as the fallback build ID.

Remaining release evidence for this optional-feature milestone: runtime-loaded curl on a Linux host that intentionally supplies ambient libcurl, a real Qt Core target build if Qt is to be advertised, and lower-bound dependency testing. The default linked-curl loopback passes on remote Linux x86_64 both uncompressed and gzip-compressed. Core/backend native Linux runtime is proven. Qt is therefore an injection contract, not a currently verified feature.

### Milestone 4 progress report — Breakpad

Implemented:

- Private native rules_cc `//:breakpad_client` with exact common, Linux, macOS, assembly, header, framework, and compatibility selections from `external/CMakeLists.txt`.
- Private `_sentry_breakpad_backend` C++17 adapter with the same compile definitions as the selected Sentry core and a transitive Breakpad dependency selected through `//config:breakpad_client`.
- Linux hermetic `breakpad_getcontext.S`, narrow explicit LSS header target, macOS Objective-C++ compilation, and the CoreServices-to-CoreFoundation compatibility header required by the LLVM SDK.
- Linux/macOS/CPU compatibility gates and deferred Windows incompatibility.
- Public-API crash fixture that forks a child, triggers `sentry_crash`, and validates `last_crash`, the matching `.crash`/`.envelope` pair, fatal event metadata, `breakpad` integration, `event.minidump`, and `MDMP` payload magic.

Verification:

- CMake baseline from the pinned source: 17-object macOS `libbreakpad_client.a`, separate from `libsentry.a`; its crash envelope shape matches the Bazel fixture assertions.
- CMake-versus-Bazel compiled-source comparison: empty diff for all 27 Linux and 17 macOS actions. No Breakpad test or tool source enters the target.
- Breakpad client builds: macOS arm64/x86_64 and Linux glibc 2.28 x86_64/aarch64 passed with LLVM. Archives and `breakpad_getcontext` ELF architecture/symbols were inspected.
- Integrated `//:sentry`: macOS arm64 smoke and real crash-artifact runtime passed; macOS x86_64 and Linux glibc 2.28 x86_64/aarch64 crash-test binaries linked and their Mach-O/ELF architectures were inspected.
- macOS Breakpad unit lane: 567 applicable upstream tests passed. Only the stale crash-time-logger-default assertion is excluded.
- Isolated consumer module: linked and ran with Breakpad without access to root LLVM dependencies.
- Final link action inspection shows Sentry core, backend adapter, Objective-C++ object, and 17 Breakpad client objects as separate transitive inputs, confirming Bazel—not a pre-merged archive—owns dependency collection.
- Explicit `//:breakpad_client` build produces a 17-member archive matching the CMake artifact boundary.

Native Linux arm64 completion: both the static and shared Breakpad crash-artifact tests pass with LLVM glibc 2.28. Each test forks a crashing process and validates the persisted fatal minidump envelope, closing the two-OS runtime gate. The same static/shared fixtures also pass on BuildBuddy Linux x86_64 remote workers.

### Milestone 5 progress report — Crashpad

Implemented:

- Exact release-archive copies of Crashpad's nested Mini Chromium, zlib, and Linux syscall-support trees. They are force-tracked because upstream nested `.gitignore` files otherwise make a clean overlay checkout differ from the official recursive release asset.
- Private native rules_cc targets for `crashpad_interface`, `mini_chromium`, `crashpad_compat`, `crashpad_getopt`, `crashpad_mpack`, `crashpad_zlib`, and `crashpad_tools`.
- Exact Linux/macOS source, header, Objective-C++, compile-definition, include, framework, pthread, and `dl` selections from the pinned Crashpad CMake graph. This includes `CRASHPAD_FLOCK_ALWAYS_SUPPORTED=1`, embedded LSS, Linux large-file definitions, C++17, and the Bzlmod zlib mapping.
- Exact compatibility gates for Linux/macOS x86_64/aarch64. Deferred platforms, including Windows, are analysis-incompatible.
- A development-only `@llvm` macOS SDK framework closure. This extends LLVM's hermetic archive through an `osx.frameworks` tag without importing its repository into the published module graph or falling back to the host SDK.

Verification:

- All foundation targets build with LLVM for Linux glibc 2.28 x86_64/aarch64 and macOS arm64/x86_64.
- Compile-action source sets were compared with CMake's platform selections; no tests, fuzzers, tools outside the explicit tools target, or deferred-platform sources enter the archives.
- The macOS x86_64 archive was inspected as Mach-O x86-64.
- An explicit Windows build is rejected as incompatible.
- `bazel mod tidy` passes with the development-only framework tag and no root `use_repo` for LLVM's SDK.
- The same foundation target builds through the isolated BCR-style consumer module without resolving the root LLVM development dependency.

Linux util/client checkpoint:

- `crashpad_util` contains exactly 78 compiled objects: 41 common, 14 POSIX, and 23 Linux. `crashpad_client` contains 10: six common and four Linux. These source sets match the pinned CMake selections and exclude tests, fuzzers, Android-only sources, and `pthread_create_linux.cc`.
- LLVM glibc 2.28 x86_64 and aarch64 builds pass. An extracted aarch64 util object was inspected as ELF AArch64.
- Crashpad's Linux upload transport compiles against curl headers independently of Sentry's transport setting and resolves its API with `dlopen`/`dlsym`, matching upstream. The Bazel handler supplies BCR curl as a private shared runtime instead of relying on an ambient system library. Zlib, pthread, and `dl` remain transitive native Bazel inputs.
- `//:sentry` now maps both `backend=auto` and explicit `backend=crashpad` to the C++ Crashpad adapter on supported desktop platforms. Linux x86_64 explicit and Linux aarch64 auto builds pass. A linked smoke binary contains one adapter, 10 client, and 78 util objects as separate Bazel linker inputs and is ELF for the selected architecture.
- `crashpad_stacktrace=true` with the Crashpad backend is analysis-incompatible. The current Sentry libunwind target is local-only; the option requires a distinct generic remote-unwind plus ptrace graph on Linux and Crashpad's forked libunwind on macOS.
- Reordering the Sentry warning flags keeps `-Wno-gnu-include-next` after `-Wpedantic`, preserving upstream's SYSTEM-header suppression once Crashpad's Linux compatibility include directory becomes transitive.

Completed implementation and verification:

- macOS `crashpad_util` contains 92 compiled objects and `crashpad_client` contains 9, matching the exact CMake baseline on arm64. All 16 MIG outputs are generated from the pinned `.defs` inputs. The source-built MIG 138 outputs are byte-identical to Apple MIG 138 from Xcode 26.5 when both use the same Crashpad scripts, SDK, Clang, definitions, and include roots.
- MIG generation is fully declared and remote-capable. The rule executes the unchanged Crashpad `mig.py`, `mig_fix.py`, and `mig_gen.py` with a file-backed rules_python execution runtime; invokes the unchanged upstream `mig.sh` and source-built `migcom` as execution tools; and derives Clang and the SDK sysroot from the selected target `@llvm` C++ toolchain. Four independent actions declare the toolchain, Python runtime, SDK, definitions, and compatibility headers as inputs. There are no `xcrun`, local-only, no-cache, or no-remote markers.
- Apple MIG's parser and lexer are checked in as the inputs of `//bazel/apple_mig:migcom_parser`. The private source-built `@apple_mig//:migcom` target consumes that library through Bzlmod's owner-module repository mapping. The maintainer-only regeneration script verifies the archive checksum and exact Apple Bison 2.3/Flex 2.6.4 versions; normal builds have no Bison or Flex dependency.
- Linux x86_64 remote workers cross-build the complete `//:sentry` and `//:crashpad_handler` graphs for macOS arm64 and x86_64. Action-query confirms every `CrashpadMig` action uses the Linux x86_64 execution platform, Linux rules_python runtime, Linux-built MIG tools, and target `@llvm` Clang/SDK. The outputs were inspected as arm64 and x86_64 Mach-O executables respectively.
- Native rules_cc snapshot, minidump, handler-library, and handler-binary targets now cover Linux and macOS. Platform-specific archive member counts are Linux x86_64 39/26/10, Linux aarch64 38/26/10, macOS x86_64 33/26/9, and macOS arm64 32/26/9 for snapshot/minidump/handler library respectively. The variations are the expected CPU-specific source selections.
- Seven macOS `.proctype` headers that CMake made available implicitly are explicit `textual_hdrs`; the Bazel sandbox exposed that undeclared-input boundary before runtime validation.
- Linux links `client/pthread_create_linux.cc` directly into `crashpad_handler`, preserving its interposition semantics instead of placing it in an archive. The final handler exports the expected global `pthread_create` symbol.
- `//:crashpad_handler` is public and the private Crashpad backend carries it as runtime data, not as a link dependency. Final Sentry link actions still gather the adapter, client, util, zlib, and platform libraries transitively rather than merging them into `libsentry.a`; the handler alone carries the private shared curl runtime.
- Crashpad's compatibility header roots are exported through a private compilation context as ordinary `-I` paths. This preserves the upstream `signal.h`, `sys/mman.h`, `sys/ptrace.h`, `sys/user.h`, and macOS SDK wrapper precedence with both Bazel 8 and Bazel 9, including when sentry-native is an external module.
- `crashpad_stacktrace=true` remains analysis-incompatible. Linux requires Crashpad's generic remote-unwind and ptrace graph, while macOS requires Crashpad's forked libunwind; the existing local-only Sentry unwind target is not a valid substitute.
- Fresh exact-source CMake differential baseline on macOS arm64: util 92, client 9, snapshot 32, minidump 26, handler library 9; both CMake and Bazel handlers report Crashpad 0.8.0.
- macOS arm64 end-to-end crash coverage passed. A child starts the Bazel-built handler through the public SDK, crashes, waits for upload, receives a loopback HTTP multipart body in either fixed-length or chunked form, inflates gzip when present, validates `MDMP`, `integrations`, `crashpad`, and fatal metadata, and verifies the persisted minidump magic.
- Invalid explicit handler paths fail initialization as expected. Colocated-handler discovery is exercised by a hermetic Bazel symlink action that places the declared handler output beside the unit binary without invoking `cp`, `ln`, or another host shell tool.
- The macOS arm64 upstream unit lane passes all 568 cases applicable to `transport=none`. A baseline run without adjacent staging failed 148 tests because backend startup correctly rejected the missing handler; the staged rerun passed without modifying upstream test sources.
- The isolated BCR-style consumer, which does not resolve the root `@llvm` development dependency, builds and runs a Crashpad smoke test when the public handler is passed through the SDK's explicit handler-path API.
- macOS x86_64 crash fixtures link successfully. Linux glibc 2.28 x86_64 and aarch64 crash fixtures, including the SDK, client graph, and handler, cross-build successfully with `@llvm`.
- Deferred Windows and other unsupported platforms, plus unsupported Crashpad stacktrace combinations, fail during analysis as incompatible.

Linux completion:

- Native Linux arm64 LLVM glibc 2.28 passes the static and shared Crashpad crash-artifact tests plus invalid-handler negative coverage. The fixture observes the handler upload, validates multipart/gzip handling, and checks the produced minidump/report rather than relying only on exit status.
- BuildBuddy Linux x86_64 and arm64 remote execution passes static/shared Crashpad crash-artifact tests and invalid-handler coverage from an exact staged-registry consumer. Before the shared curl runtime was added, both crash fixtures reached the handler but timed out after its `dlopen` search found no system libcurl; the fixed test completes in under a second.
- Bazel 8.4.2 exact-registry tests with consumer-owned `@llvm` pass the same static/shared Crashpad artifact and invalid-handler suite on remote Linux arm64 and native macOS arm64. On macOS, private C++ archive adapters preserve the three Objective-C++ libraries when `cc_shared_library` gathers transitive linker inputs.
- The Linux handler artifact has the expected target architecture, `DT_NEEDED` entry for `libcurl.so`, Bazel-generated RUNPATH into its solib tree, and an undefined versioned `curl_version` binding. It no longer embeds the static curl implementation.

### Milestone 6 report — native backend and `sentry-crash`

Implemented:

- Public `//:sentry_crash` companion binary and the selected native SDK backend for Linux/macOS.
- Exact native library and daemon source manifests: 54 and 58 translation units respectively on macOS, matching the pinned CMake graph.
- Linux vendored remote-unwind graph with `_UPT` and target-specific remote symbols; the SDK library retains the local unwind graph.
- C11 for the library-side native implementation and upstream C99 behavior for the standalone daemon.
- Companion-artifact runfiles propagation and a black-box fixture that launches the daemon, crashes a child, and validates the resulting artifact.

Verification:

- macOS arm64 real-crash fixture passed against both Bazel and the exact 0.16.6 CMake baseline; the integrated post-merge fixture also passed uncached.
- Native Linux arm64 LLVM glibc 2.28 real-crash fixture passed.
- macOS x86_64 and Linux glibc 2.28 x86_64/aarch64 binaries cross-build; Mach-O/ELF architecture, symbols, daemon presence, and unwind archive membership were inspected.
- The isolated consumer builds `@sentry_native//:sentry_crash` without resolving the root LLVM development dependency.
- Windows and non-native backend requests are analysis-incompatible.

### Milestone 7 report — deployable shared library

Implemented:

- Public `//:sentry_shared` as the actual `cc_shared_library`, producing `libsentry.so` or `libsentry.dylib`.
- Public `//:sentry_shared_library` as the CcInfo-bearing wrapper used by ordinary `cc_binary.deps` edges.
- Separate core, Breakpad adapter, Crashpad adapter, and Qt compilation roots using `SENTRY_BUILD_SHARED`; `//:sentry` retains its distinct static compilation root.
- Linux version-script, SHA-1 build ID, and SONAME behavior; macOS explicit public export list and `@rpath/libsentry.dylib` install name.

Verification:

- Action inspection proves distinct static/shared objects and definitions.
- Native macOS arm64 runtime passed for none, inproc, Breakpad crash artifacts, and Crashpad crash artifacts. The macOS x86_64 Crashpad shared consumer cross-build passed.
- Native Linux arm64 static/shared Breakpad and Crashpad crash artifacts passed. Linux x86_64/aarch64 shared Crashpad artifacts and consumers cross-build with the expected ELF architecture, SONAME, and SHA-1 build ID.
- Linux exports are 423 `sentry_*` names only. The exact none/none CMake and Bazel macOS artifacts expose the same 421-symbol API, the same install name, and only `libSystem` after dead dylib stripping.
- The isolated consumer builds `@sentry_native//:sentry_shared` and runs through `@sentry_native//:sentry_shared_library` without LLVM dependency leakage.

### Milestone 8 progress report — BCR overlay and registry consumption

Implemented:

- Explicit root `BUILD.bazel` declarations for the Breakpad, Crashpad, and Sentry graphs. No target-declaration-only macro or Bazel-owned file below either submodule path remains, while `//:sentry`, `//:sentry_shared`, `//:sentry_shared_library`, `//:crashpad_handler`, and `//:sentry_crash` remain stable.
- Small BCR publication inputs under `.bcr/`: a metadata template plus versioned presubmit configuration, explicit 48-file manifest, and immutable release descriptor. The complete module entry is generated only in an official BCR checkout.
- Archive provenance against the official `sentry-native.zip`: SHA-256 `d35145daaafddc50c0c87ec564acf0ba9968e67b23981e7f57c702b2dd6f2ff1`, no `strip_prefix`, and per-overlay SRI values generated by the official BCR integrity tool.
- Presubmit coverage for Bazel 8.x/9.x minimal public targets on Linux/macOS x86_64/aarch64; Bazel 9 Breakpad, Crashpad, and native backend artifact tests on all four desktop architecture runners; Linux-only anonymous Bazel 8 Crashpad/default lanes; and Bazel 8/9 static/shared Crashpad consumer tests. The LLVM-owning `bcr_test_module` supplies the Bazel 8 macOS default lane because anonymous modules cannot inherit a dependency's development toolchain.
- A shared-library Crashpad smoke consumer in `e2e/bcr`, complementing the existing static consumer.
- Consumer-owned LLVM development setup in `e2e/bcr`, including the macOS framework projection required by Bazel 8 Objective-C++ compilation; no LLVM label appears in the production graph.
- Module compatibility declaration `bazel_compatibility = [">=8.4.2"]`, matching the lowest version actually exercised.
- Apple MIG's checked-in lexer/parser outputs are ordinary overlay files under `bazel/apple_mig/migcom`, exposed by the semantic `//bazel/apple_mig:migcom_parser` target. The upstream archive is no longer patched; `@apple_mig//:migcom_headers` and `@apple_mig//:migcom_non_apple_headers` expose only the corresponding source headers.
- Breakpad's vendored LSS header is owned by a root-package target and exposed under its source-level `third_party/lss` namespace with `include_prefix`; the graph no longer exports a parent directory through `includes = ["../.."]`. Bazel normalizes the reserved physical `external/third_party/lss/...` path to logical `lss/...`, so adding the `third_party` prefix is sufficient and an explicit physical `strip_include_prefix` is invalid in an external-module consumer.
- The implementation now lives on a true upstream-descended fork branch with recursive submodules. `.bcr/releases/0.16.6/release.json` pins the upstream tag/commit, official archive identity, and exact fork overlay commit; verification rejects changed gitlinks, mismatched checkouts, or canonical files that drift from that pin.
- Fork-owned shell tooling under `tools/bcr/` extracts the pinned overlay into an official registry checkout, invokes the official integrity updater, accepts only documented validator statuses, materializes official presubmit repositories, and runs the exact generated consumer. `tools/bcr/README.md` documents the complete next-release procedure.
- Pinned GitHub Actions run Bazel 8.4.2/9.2.0 minimal static/shared consumers on Linux and macOS, validate the exact BCR assembly on Linux, and upload the prepared module. Publication is a separate explicit `publish=true` dispatch requiring `BCR_PUBLISH_TOKEN`; it creates the version branch in `cerisier/bazel-central-registry` and opens the upstream pull request.

Verification:

- After flattening the declaration macros and moving the LSS header provider to the root package, `//:all` exposes the complete 51-target root graph. The none/none unit target, native macOS static/shared Breakpad artifacts, and native macOS Crashpad client/negative/static/shared tests passed uncached. The linked output remains an arm64 Mach-O `libsentry.dylib` with the expected public `sentry_*` symbol surface, and action-query reports the final shared-library link plus solib symlink actions.
- Native macOS LLVM builds passed for the relocated Breakpad and Crashpad clients, private handler, static SDK, and shared SDK. macOS Crashpad static/shared artifacts and negative-handler coverage passed; macOS Breakpad static/shared crash artifacts also passed.
- The isolated BCR consumer passed remote Linux x86_64 static/shared crash-artifact tests for both Crashpad and Breakpad. The root remote attempt reproduced the already-documented `_main` sibling-layout infrastructure failure; the ordinary external-module consumer explicitly disables that root-only layout and passes.
- Overlay synchronization reports exactly 53 canonical files, official BCR validation reports every automated check good, and the official integrity updater accepts the regenerated archive and overlay SRI values. The sole validation exit condition is the expected maintainer review for a new module.
- The external-module Linux x86_64 build and uncached Breakpad crash-artifact test pass after replacing the LSS parent-directory include. Action inspection reports only the scoped `_virtual_includes/_breakpad_lss` root, whose single symlink exposes `third_party/lss/linux_syscall_support.h`; no `..`-based include directory reaches compiler actions.
- Official BCR validation passed archive integrity, stable/source repository checks, overlay/module assembly, metadata identity, and presubmit schema. The only review result is the expected maintainer review for a new module's presubmit.
- The official `setup_presubmit_repos` tool at BCR commit `90343df1301b2970238f37ac3b8fcb3abf8fea9a` materialized the contribution from the release archive plus its explicit overlay, then prepared both the anonymous consumer and the exact checked-in `e2e/bcr` test module. This is the same repository-construction boundary used by BCR presubmit rather than a local-path approximation.
- After replacing the Apple MIG archive patch with semantic source targets, the official integrity updater and validation tool accepted the new overlay, and `setup_presubmit_repos` rematerialized it successfully. The materialized module's MODULE, MIG BUILD files, reproduction script, and three parser/lexer files are byte-identical to their canonical overlay inputs, with no archive-patch configuration or generic generated-source identifiers. Focused `@apple_mig//:migcom` and 16-output Crashpad MIG code-generation builds pass.
- From that materialized test module, Bazel 9.2.0 cross-built `@sentry_native//:sentry` and `@sentry_native//:crashpad_handler` for macOS arm64 and x86_64 on BuildBuddy Linux x86_64 workers. Bazel 8.4.2 also completed the macOS arm64 cross-build, covering the declared version floor. The complete Bazel 9 arm64 graph contained 1,312 actions; the Bazel 8 arm64 graph contained 1,309. The downloaded handlers were inspected as Mach-O arm64 and x86_64, and `libsentry.a` contained the expected 50 Sentry objects.
- Action-query of the materialized module reports four `CrashpadMig` actions on `@llvm//:rbe_linux_x86_64`, invoking the Linux rules_python interpreter, unchanged Crashpad `mig.py`, Linux-built Apple MIG tools, and the selected macOS `@llvm` Clang/sysroot. This verifies the published archive-plus-overlay graph rather than only the fork checkout.
- A clean anonymous consumer fetched `sentry_native@0.16.6` through the staged file registry plus the public BCR, proving the build did not use the source checkout or `local_path_override`.
- Bazel 9.2.0 built static and shared none/none consumers and ran static and shared Crashpad consumers on native macOS arm64.
- Bazel 8.4.2 built the same static and shared none/none registry consumers, passed exact-registry static/shared Crashpad artifact tests on remote Linux arm64, and passed literal-default static/shared Crashpad artifacts in the LLVM-owning test module on native macOS arm64. This establishes the declared 8.4.2 floor for minimal and default-backend graphs without pretending sentry-native's development dependencies propagate to anonymous consumers.
- The checked-in `e2e/bcr` module ran its static and shared Crashpad consumers uncached on native macOS arm64 with both Bazel 8.4.2 and 9.2.0 using its own `@llvm` dev dependency. A baseline Bazel 8 attempt without consumer toolchain registration failed during `objc_library` analysis, proving the coverage exercises the intended ownership boundary.
- The same checked-in static/shared consumer tests passed uncached with Bazel 8.4.2 and 9.2.0 on BuildBuddy Linux x86_64 and arm64 workers after explicitly pairing LLVM target and execution platforms. The deliberately reproduced mismatched x86_64-target/arm64-worker run failed at execution with `Exec format error`, proving the lane runs the artifact rather than only compiling it.
- After the rules_cc compatibility fixes, overlay sync, and integrity regeneration, the official BCR tool at commit `a62aa8ffa` reassembled the archive-plus-overlay test module. Bazel 8.4.2 and 9.2.0 both passed uncached literal-default static and shared Crashpad artifact tests on the explicit Linux x86_64 LLVM target/execution pair. This validates archive download, overlay application, module dependency resolution, linked-curl defaults, shared runtime runfiles, and actual process execution together.
- After the final rules_cc refactor, literal-default static/shared Crashpad artifact tests passed uncached with Bazel 8.4.2 and 9.2.0 on remote Linux x86_64; Bazel 9.2.0 also passed them on remote Linux aarch64. These commands supplied no sentry-native build-setting overrides, exercising the actual default backend, linked curl transport, compression, and screenshot choices.
- Native-backend static/shared crash-artifact tests with `embed_info=true` passed uncached on remote Linux x86_64/aarch64 and native macOS arm64. The generated metadata C++ action is separate from GNU C backend actions and remains force-linked into the artifacts.
- An action-query of an external none/none consumer shows only the public `sentry.h` virtual include tree, not the repository's private `src/` or native-daemon include roots. A configured dependency-path query proves `sentry_shared_library` carries `sentry_crash` in native mode.
- Explicit musl target requests for `//:sentry` and `//:crashpad_handler` fail as analysis-incompatible, while the corresponding glibc 2.28 targets analyze successfully. This matches the first-release scope rather than the wider set of exploratory cross-builds.
- Crashpad implementation targets are package-private; only the root-owned client/handler edges and documented root public targets remain visible outside `external/crashpad`.
- BuildBuddy Linux x86_64 and arm64 remote execution with consumer-owned `@llvm` passed the complete staged-registry Crashpad artifact/negative suite. Linux x86_64 additionally passed all 568 applicable none/none unit cases, static/shared Breakpad crash artifacts, and the native backend crash artifact. The root-only sibling layout flag was explicitly disabled because ordinary BCR consumers neither need nor inherit it.
- BuildBuddy Linux arm64 also passed the native-backend crash artifact. Its Breakpad artifact alone recurses inside the remote sandbox and times out; an earlier container diagnostic passed the same architecture, but the staged BCR presubmit's native `ubuntu2004_arm64` Breakpad runtime remains the release gate.
- The registry-produced Linux shared artifact was inspected as AArch64 ELF, `DYN`, SONAME `libsentry.so`, SHA-1 build ID, expected system `NEEDED` entries, and exactly 423 defined `sentry_*` exports.
- From a fresh official BCR checkout at `fde2926e09c7250c6484c109671ab39227c8598b`, the new exporter reproduced `sentry_native@0.16.6`; `bcr_validation` reported every automated check good and only the expected new-module maintainer-review status. `setup_presubmit_repos` then reconstructed both official test repositories from the getsentry ZIP plus overlay.
- The newly materialized `e2e/bcr` consumer passed its default static and shared Crashpad runtime tests on native macOS arm64 with both Bazel 9.2.0 (2,147 actions) and the declared floor Bazel 8.4.2 (2,143 actions). Both runs used the consumer-owned LLVM toolchain and exercised source-built Apple MIG before launching the handler-backed tests.
- The real fork checkout with initialized submodules built `//:sentry`, `//:sentry_shared`, `//:sentry_shared_library`, and both none/none smoke consumers with Bazel 9.2.0; the static and shared binaries both ran. Artifact inspection reports an arm64 `libsentry.dylib`, `@rpath/libsentry.dylib`, only `libSystem` as a runtime dependency, and 421 exported `sentry_*` symbols. Action-query reports four C++ link actions for the shared target closure.
- Before removal of the redundant staging copy, re-running the official BCR integrity updater produced no diff. The replacement generator now recomputes all archive and overlay SRI values in the target BCR checkout and compares the downloaded archive against the immutable release descriptor.
- After promoting the Bazel branch to fork `master`, manually dispatched run `35141651394` passed all four smoke lanes: Ubuntu 24.04 and macOS 14 with Bazel 8.4.2 and 9.2.0. Run `35141654259` passed official BCR export, validation, materialization, the exact default static/shared Crashpad consumer, and prepared-module upload. Its publication job was intentionally skipped because the dispatch set `publish=false`. Fork branch `upstream` remained exactly `0d5bec47307cba89af85525d0d1bd7fbf799c8cd`, equal to `getsentry/master` during the migration.

### Publication-layout hardening report

- Removed the checked-in `bcr/modules/sentry_native` publication copy. Canonical Bazel files now exist only at their source-checkout paths; generated module metadata, `MODULE.bazel`, `source.json`, overlay copies, and integrity values exist only in the target BCR checkout.
- Retained only compact, versioned inputs under `.bcr/releases/0.16.6`: the release descriptor, explicit 48-file manifest, and presubmit configuration. The descriptor pins the exact overlay commit as well as the upstream tag, commit, and official archive identity.
- Replaced staging synchronization/export scripts with `tools/bcr/prepare_entry.sh`. It extracts `MODULE.bazel` and every manifest-selected file from the pinned commit, merges module metadata without discarding BCR-owned version history, invokes the official integrity updater, and verifies the resulting archive identity and overlay boundary.
- Updated CI so validation generates the entry in a fresh official BCR checkout. The publication job downloads that validated module artifact and commits those exact bytes instead of regenerating them independently.
- Corrected the `publish-to-bcr` finding: it can target the official getsentry archive URL. The current incompatibility is its requirement that `MODULE.bazel` already be present in the archive and its lack of BCR overlay support.

Verification:

- `tools/bcr/verify_release.sh 0.16.6` reports exactly the 48 files pinned to the overlay commit.
- Generation against a fresh current BCR checkout produced a module subtree byte-for-byte identical to the former checked-in entry, including `source.json` and every computed SRI value.
- Current official `bcr_validation` passed source URL, archive integrity, overlay/module assembly, metadata identity, and presubmit syntax; only the expected first-version maintainer review remained. Current `setup_presubmit_repos` successfully materialized both official consumer repositories.
- A subsequent native macOS runtime invocation reached analysis and compilation but the host exhausted disk space while rebuilding LLVM. This was an environment failure after the generated-entry equivalence and official validation checks; the identical former entry's Bazel 8/9 runtime results remain recorded above.

### Embedded-info simplification report

Implemented:

- Replaced the custom `sentry_embedded_info` rule with a native `genrule` whose only command dependencies are Bazel's standard genrule shell setup and shell builtins.
- Replaced `c_string_flag` and `bounded_int_flag` with Skylib `string_flag` and `int_flag`; values are forwarded without extra Starlark validation.
- Removed the `embed_info_items` setting and its custom field emission from the Linux/macOS port.
- Retained target-derived `Linux`/`Darwin` defaults, semantic-version base extraction, explicit build-ID precedence, SDK build-metadata fallback, deterministic `unstamped`, build variant, and compilation mode.
- Enabled embedded metadata in the Bazel 8/9 Linux/macOS static/shared BCR consumer presubmit task so the generated source remains a publication gate.

Verification:

- The macOS output with defaulted platform/variant/build-ID settings and SDK build metadata is byte-identical to the previous custom rule. Explicit platform, variant, and build-ID overrides produce the same prior fields, excluding the intentionally removed custom item.
- macOS arm64 static/shared none-backend builds with `embed_info=true` pass, and the focused embedded-info unit cases pass.
- The isolated BCR consumer remotely generated the Linux x86_64 source with `PLATFORM:Linux` and passed the focused embedded-info unit cases on the paired LLVM/BuildBuddy x86_64 target and worker with Bazel 8.4.2 and 9.2.0.
- The presubmit-equivalent static and shared Crashpad consumers pass on Linux x86_64 remote workers with Bazel 9.2.0 and `embed_info=true`.
- The exact Bazel 8.4.2 Linux consumer initially exposed a separate Crashpad header-order regression: `cc_library.includes` placed the compat directory after the LLVM sysroot and `exception_snapshot_linux.cc` failed on an undeclared `X86_FXSR_MAGIC`. Native header-only `cc_library` virtual include trees restore upstream wrapper precedence. Action-query shows the compat roots as ordinary `-I` inputs, and remote Bazel 8.4.2 plus 9.2.0 static/shared Crashpad consumers pass with embedded metadata enabled.
- Repository-aware prefix selection is verified in both layouts: Bazel 8.4.2 analyzes the root Linux Crashpad snapshot graph, Bazel 9.2.0 compiles that root graph through `exception_snapshot_linux.cc`, and Bazel 8.4.2 analyzes and runs the external-module graph. The Linux, macOS, and non-macOS compat header targets also analyze in their corresponding root and external configurations.
- Before the compatibility-only cleanup, official BCR tooling at registry commit `bdc710ce16c6ddef9cd9bdb7b4e8c554f5449ce1` validated the 49-file overlay, accepted the official archive/integrity/metadata/presubmit boundary, and materialized both official consumer repositories. The only validation status was the expected maintainer review for a new module.
- From that exact archive-plus-overlay test module, uncached static and shared Crashpad consumers with embedded metadata pass on paired Linux x86_64 remote workers under Bazel 8.4.2 (invocation `fb0fad51-1713-40aa-9520-ed58bccfb598`) and Bazel 9.2.0 (invocation `fec185a9-d5a7-406b-8333-0cf41c87a313`).
- The exact materialized static/shared consumers also pass uncached on native macOS arm64 with Bazel 8.4.2 (invocation `e3aa770f-940c-4051-b11a-4d7d28328a6d`) and Bazel 9.2.0 (invocation `a3df9fd4-ccf4-48c1-be5b-0456089762b8`). Before materialization, one first Bazel 8 shared run from the local-path consumer segfaulted during SDK shutdown; three immediate uncached reruns and the exact BCR run passed. Retain that isolated failure as a recorded runtime flake and the official native macOS lane as the publication gate.
- Direct root remote execution still hits the previously documented sibling-layout `_main` input-tree failure; the external-module consumer topology is the valid remote verification path.

### Compatibility-ownership simplification report

Implemented:

- Removed `bazel/sentry.bzl`; its root-only platform, setting, and implementation-define values now live next to their consumers in the root `BUILD.bazel`.
- Retained the supported-core policy because the settings deliberately accept values for deferred ports: WinHTTP, pshttp, Windows screenshots, and Crashpad client-side stacktraces. The policy now appears only on SDK entry targets instead of every private helper.
- Removed platform compatibility duplication from generic Sentry and Crashpad helper libraries. Public/top-level targets and genuinely Linux-only or macOS-only targets remain explicitly constrained; dependency incompatibility covers the internal graph.
- Moved the Crashpad stacktrace incompatibility to the handler entry target and removed its repeated helper from the source-manifest file.
- Reduced the release overlay from 49 to 48 files.

Verification:

- Buildifier and root-package loading pass.
- On the explicit LLVM macOS arm64 platform, configured queries resolve `libsentry.a`, `libsentry.dylib`, the Crashpad handler, and the native crash daemon.
- Configured queries return no compatible public output for WinHTTP, Windows screenshots, Crashpad stacktraces, or LLVM musl.
- Action-query resolves 2,584 static and 2,586 shared actions for the default supported macOS arm64 graph. Per the cleanup policy, no compile or runtime test matrix was repeated.

On final completion, also record:

- Published targets and tested configuration matrix.
- Bazel and dependency version range.
- CMake-versus-Bazel artifact comparison results.
- Known unsupported or compile-only platform/configuration combinations.
- BCR pull request and upstream pull request references.
- Any changes to the planned public contract.

"""Pure attribute helpers for the root sentry-native BUILD graph."""

def sentry_supported_platforms():
    return select({
        "//config:linux_aarch64": [],
        "//config:linux_x86_64": [],
        "//config:macos_aarch64": [],
        "//config:macos_x86_64": [],
        "//conditions:default": ["@platforms//:incompatible"],
    }) + select({
        "@rules_cc//cc/libc:glibc": [],
        "@rules_cc//cc/libc:macosx": [],
        "//conditions:default": ["@platforms//:incompatible"],
    })

def sentry_supported_core_configuration():
    return select({
        "//config:backend_breakpad": [],
        "//config:backend_crashpad_or_auto_stacktrace_disabled": [],
        "//config:backend_custom": [],
        "//config:backend_inproc": [],
        "//config:backend_native": [],
        "//config:backend_none": [],
        "//conditions:default": ["@platforms//:incompatible"],
    }) + select({
        "//config:transport_auto": [],
        "//config:transport_curl": [],
        "//config:transport_custom": [],
        "//config:transport_none": [],
        "//conditions:default": ["@platforms//:incompatible"],
    }) + select({
        "//config:screenshot_auto": [],
        "//config:screenshot_custom": [],
        "//config:screenshot_none": [],
        "//conditions:default": ["@platforms//:incompatible"],
    })

def sentry_implementation_defines():
    return [
        "SENTRY_BATCHER_BUFFER_COUNT=$(SENTRY_BATCHER_BUFFER_COUNT_VALUE)",
        "SENTRY_HANDLER_STACK_SIZE=$(SENTRY_HANDLER_STACK_SIZE_VALUE)",
    ] + select({
        "//config:linux_aarch64": [
            "SENTRY_WITH_UNWINDER_LIBUNWIND",
            "SIZEOF_LONG=8",
        ],
        "//config:linux_x86_64": [
            "SENTRY_WITH_UNWINDER_LIBUNWIND",
            "SIZEOF_LONG=8",
        ],
        "//config:macos_aarch64": [
            "SENTRY_WITH_UNWINDER_LIBUNWIND_MAC",
            "SIZEOF_LONG=8",
        ],
        "//config:macos_x86_64": [
            "SENTRY_WITH_UNWINDER_LIBUNWIND_MAC",
            "SIZEOF_LONG=8",
        ],
        "//conditions:default": [],
    }) + select({
        "//config:backend_breakpad": ["SENTRY_BACKEND_BREAKPAD"],
        "//config:backend_crashpad_or_auto": ["SENTRY_BACKEND_CRASHPAD"],
        "//config:backend_inproc": [
            "SENTRY_BACKEND_INPROC",
            "SENTRY_WITH_INPROC_BACKEND",
        ],
        "//config:backend_native": [
            "SENTRY_BACKEND_NATIVE",
            "SENTRY_WITH_NATIVE_BACKEND",
        ],
        "//config:backend_none": [],
        "//conditions:default": [],
    }) + select({
        "//config:screenshot_auto": ["SENTRY_SCREENSHOT_NONE"],
        "//config:screenshot_custom": ["SENTRY_SCREENSHOT_CUSTOM"],
        "//config:screenshot_none": ["SENTRY_SCREENSHOT_NONE"],
        "//conditions:default": [],
    }) + select({
        "//config:transport_auto_link_curl_auto": ["SENTRY_LINK_CURL"],
        "//config:transport_auto_link_curl_on": ["SENTRY_LINK_CURL"],
        "//config:transport_curl_link_curl_auto": ["SENTRY_LINK_CURL"],
        "//config:transport_curl_link_curl_on": ["SENTRY_LINK_CURL"],
        "//conditions:default": [],
    }) + select({
        "//config:transport_compression_enabled": ["SENTRY_TRANSPORT_COMPRESSION"],
        "//conditions:default": [],
    }) + select({
        "//config:integration_platform_enabled": ["SENTRY_INTEGRATION_PLATFORM"],
        "//conditions:default": [],
    }) + select({
        "//config:integration_qt_enabled": ["SENTRY_INTEGRATION_QT"],
        "//conditions:default": [],
    }) + select({
        "//config:embed_info_enabled": ["SENTRY_EMBED_INFO=1"],
        "//conditions:default": [],
    })

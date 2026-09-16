"""Hermetic generation of sentry-native's optional embedded build metadata."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")

def _c_string(value):
    return value.replace("\\", "\\\\").replace("\"", "\\\"").replace("\r", "\\r").replace("\n", "\\n")

def _semver_base(version):
    parts = version.split(".")
    if len(parts) < 3 or not parts[0].isdigit() or not parts[1].isdigit():
        fail("sdk_version must begin with a semantic major.minor.patch: {}".format(version))

    patch = ""
    for char in parts[2].elems():
        if not char.isdigit():
            break
        patch += char
    if not patch:
        fail("sdk_version must begin with a semantic major.minor.patch: {}".format(version))
    return "{}.{}.{}".format(parts[0], parts[1], patch)

def _embedded_info_impl(ctx):
    version = ctx.attr.sdk_version[BuildSettingInfo].value
    version_base = _semver_base(version)

    platform = ctx.attr.build_platform_name[BuildSettingInfo].value
    if not platform:
        if ctx.target_platform_has_constraint(ctx.attr._linux[platform_common.ConstraintValueInfo]):
            platform = "Linux"
        elif ctx.target_platform_has_constraint(ctx.attr._macos[platform_common.ConstraintValueInfo]):
            platform = "Darwin"
        else:
            fail("embed_info requires an explicit build_platform_name on this target platform")

    build_id = ctx.attr.build_id[BuildSettingInfo].value
    if not build_id:
        version_parts = version.split("+")
        build_id = version_parts[1] if len(version_parts) == 2 else "unstamped"

    custom_items = ctx.attr.embed_info_items[BuildSettingInfo].value
    normalized_items = []
    for item in custom_items.split(";"):
        if not item:
            continue
        fields = item.split(":")
        if len(fields) != 2 or not fields[0]:
            fail("invalid embed_info_items entry '{}'; expected key:value".format(item))
        normalized_items.append(item)

    fields = [
        "SENTRY_VERSION:{}".format(version_base),
        "PLATFORM:{}".format(platform),
        "BUILD:{}".format(build_id),
        "VARIANT:{}".format(ctx.attr.build_variant[BuildSettingInfo].value),
        "CONFIG:{}".format(ctx.var.get("COMPILATION_MODE", "")),
    ] + normalized_items + ["END"]
    embedded_info = ";".join(fields)

    output = ctx.actions.declare_file(ctx.label.name + ".cpp")
    ctx.actions.write(
        output = output,
        content = """#include \"sentry.h\"

extern \"C\" SENTRY_API const char sentry_library_info[];
extern \"C\" SENTRY_API const char sentry_library_info[] = \"{}\";
""".format(_c_string(embedded_info)),
    )
    return DefaultInfo(files = depset([output]))

sentry_embedded_info = rule(
    implementation = _embedded_info_impl,
    attrs = {
        "build_id": attr.label(
            default = "//config:build_id",
            providers = [BuildSettingInfo],
        ),
        "build_platform_name": attr.label(
            default = "//config:build_platform_name",
            providers = [BuildSettingInfo],
        ),
        "build_variant": attr.label(
            default = "//config:build_variant",
            providers = [BuildSettingInfo],
        ),
        "embed_info_items": attr.label(
            default = "//config:embed_info_items",
            providers = [BuildSettingInfo],
        ),
        "sdk_version": attr.label(
            default = "//config:sdk_version",
            providers = [BuildSettingInfo],
        ),
        "_linux": attr.label(default = "@platforms//os:linux"),
        "_macos": attr.label(default = "@platforms//os:macos"),
    },
)

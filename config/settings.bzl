"""Validated build settings for sentry-native."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")

def _template_variable_info(ctx, value):
    return platform_common.TemplateVariableInfo({
        ctx.attr.make_variable: value,
    })

def _validate_semver_prefix(ctx, value):
    parts = value.split(".")
    if len(parts) < 3 or not parts[0].isdigit() or not parts[1].isdigit():
        fail("Error setting {}: '{}' must begin with major.minor.patch".format(ctx.label, value))

    patch = ""
    for char in parts[2].elems():
        if not char.isdigit():
            break
        patch += char
    if not patch:
        fail("Error setting {}: '{}' must begin with major.minor.patch".format(ctx.label, value))

def _bounded_int_flag_impl(ctx):
    value = ctx.build_setting_value
    if value < ctx.attr.minimum or value > ctx.attr.maximum:
        fail("Error setting {}: value {} must be between {} and {}".format(
            ctx.label,
            value,
            ctx.attr.minimum,
            ctx.attr.maximum,
        ))

    return [
        BuildSettingInfo(value = value),
        _template_variable_info(ctx, str(value)),
    ]

def _c_string_flag_impl(ctx):
    value = ctx.build_setting_value or ctx.attr.value_if_empty
    if ctx.attr.require_semver:
        _validate_semver_prefix(ctx, value)
    if "\\" in value or "\"" in value or "\n" in value or "\r" in value:
        fail("Error setting {}: value cannot contain quotes, backslashes, or newlines".format(ctx.label))

    return [
        BuildSettingInfo(value = value),
        _template_variable_info(ctx, value),
    ]

def _embed_info_items_flag_impl(ctx):
    value = ctx.build_setting_value
    for item in value.split(";"):
        if not item:
            continue
        fields = item.split(":")
        if len(fields) != 2 or not fields[0]:
            fail("Error setting {}: invalid entry '{}'; expected key:value".format(ctx.label, item))
    return [
        BuildSettingInfo(value = value),
        platform_common.TemplateVariableInfo({
            "SENTRY_EMBED_INFO_ITEMS_VALIDATED": "1",
        }),
    ]

bounded_int_flag = rule(
    implementation = _bounded_int_flag_impl,
    build_setting = config.int(flag = True),
    attrs = {
        "make_variable": attr.string(mandatory = True),
        "maximum": attr.int(mandatory = True),
        "minimum": attr.int(mandatory = True),
    },
    doc = "An integer build setting constrained to an inclusive range.",
)

c_string_flag = rule(
    implementation = _c_string_flag_impl,
    build_setting = config.string(flag = True),
    attrs = {
        "make_variable": attr.string(mandatory = True),
        "require_semver": attr.bool(default = False),
        "value_if_empty": attr.string(),
    },
    doc = "A validated string build setting safe for use inside a C string macro.",
)

embed_info_items_flag = rule(
    implementation = _embed_info_items_flag_impl,
    build_setting = config.string(flag = True),
    doc = "A semicolon-separated list of embedded key:value fields.",
)

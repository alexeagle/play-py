load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

"""Definition of linter tools

This is in its own package because it has so many loading-time symbols,
we don't want to trigger eager fetches of these for builds which aren't running linters.
"""

package(default_visibility = ["//:__subpackages__"])

bzl_library(
    name = "linters",
    srcs = ["linters.bzl"],
    deps = [
        "@aspect_rules_lint//lint:lint_test",
        "@aspect_rules_lint//lint:ruff",
    ],
)

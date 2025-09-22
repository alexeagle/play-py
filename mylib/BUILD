load("@aspect_bazel_lib//lib:jq.bzl", "jq")
load("@aspect_rules_py//py:defs.bzl", "py_library", "py_pytest_main", "py_test")
load("@pip//:requirements.bzl", "requirement")
load("@rules_uv//uv:pip.bzl", "pip_compile")

# keep
filegroup(
    name = "requirements",
    srcs = ["requirements.txt"],
    visibility = ["//requirements:__pkg__"],
)

pip_compile(
    name = "pip_compile",
    requirements_in = "pyproject.toml",
    requirements_txt = "requirements.txt",
    visibility = ["//requirements:__pkg__"],
)

# Generate data.json containing build timestamp information.
# Useful with Bazel's --stamp flag.
jq(
    name = "data",
    srcs = [],
    filter = "|".join([
        # Don't directly reference $STAMP as it's only set when stamping
        # This 'as' syntax results in $stamp being null in unstamped builds.
        "$ARGS.named.STAMP as $stamp",
        # Provide a default using the "alternative operator" in case $stamp is null.
        """.TIMESTAMP = ($stamp[0].BUILD_TIMESTAMP // "<unstamped>")""",
    ]),
)

py_library(
    name = "mylib",
    srcs = ["say.py"],
    visibility = ["//:__subpackages__"],
    deps = ["@pip//cowsay"],
)

py_pytest_main(
    name = "__test__",
    deps = [
        requirement("coverage"),
        requirement("pytest"),
    ],
)

py_test(
    name = "say_test",
    srcs = ["say_test.py"],
    main = ":__test__.py",
    deps = [
        "mylib",
        "@pip//coverage",
        "@pip//pytest",
    ],
)

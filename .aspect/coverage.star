"""
Implement a 'coverage' task that wraps a test command.

Improvements over 'bazel coverage' command:

- we don't accidentally bust the analysis cache with 'coverage' flags differing from 'test'
- forget having a Bazel-specific, Java-based, unmaintained LCOV merger and 'combined report' - that never should have been Bazel's job
"""

# buildifier: disable=function-docstring
def impl(ctx) -> int:
    out = ctx.std.io.stdout
    build = ctx.build(
        "//...",
        events = True,
        bazel_flags = [
            "--isatty=" + str(int(out.is_tty)),
            # We probably want to abbreviate the following flags under
            # "--config=coverage"
            "--collect_code_coverage",
            "--instrumentation_filter=^//",
            # See https://github.com/bazel-contrib/bazelrc-preset.bzl/issues/83
            "--experimental_fetch_all_coverage_outputs",
            "--experimental_split_coverage_postprocessing",
        ],
        bazel_verb = "test",
    )

    lcov_data = []
    for event in build.events():
        # TODO: get the paths of produced (or cached) coverage report files
        # TODO: populate a GITHUB_OUTPUT variable so we can use https://github.com/codecov/codecov-action
        if event.type == "progress":
            # Bazel is dumb and doesn't produce coverage data as named_set_of_files
            if event.payload.stdout.strip().endswith("coverage.dat"):
                lcov_data.append(event.payload.stdout.strip())
                continue
            out.write(event.payload.stdout)
            out.write(event.payload.stderr)


    build.wait()
    # TODO: get the delta of changed files from VCS, and render 'incremental' coverage as the default presentation
    github_output = ctx.std.env.var("GITHUB_OUTPUT")
    if github_output:
        ctx.std.fs.write(github_output, "files=" + ",".join(lcov_data) + "\n")
    return 0

coverage = task(
    implementation = impl,
    args = {
        "targets": args.positional(min = 1),
    },
)

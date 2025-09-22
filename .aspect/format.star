"""Define the 'format' task

Format builds a multi-formatter target and then runs it on the changed files.
It's a simple example of interaction with version control, which Bazel only does via the workspace_status_command.
"""

def exec(command: command):
    return command.stdout("piped").spawn().wait_with_output().stdout.strip()

def find_changed_files(process, base_ref: str = "origin/main"):
    merge_base = exec(process.command("git").args(["merge-base", "HEAD", base_ref]))
    return exec(process.command("git").args(["diff", "--name-only", merge_base]))

# buildifier: disable=function-docstring
def impl(ctx: task_context) -> int:
    out = ctx.std.io.stdout
    changed_files = find_changed_files(ctx.std.process)
    out.write("Formatting changed files:\n%s" % changed_files)
    
    build = ctx.build(
        ctx.args.format_target or "//tools/format",
        events = True,
        bazel_flags = ["--build_runfile_links"],
    )
    for event in build.events():
        if event.type == "named_set_of_files":
            for file in event.payload.files:
                if len(file.path_prefix) == 0:
                    continue
                runfiles = file.file.uri.removeprefix("file://") + ".runfiles"
                entrypoint = file.file.uri.removeprefix("file://")
                child = ctx.std.process.command(entrypoint) \
                    .current_dir(runfiles) \
                    .env("RUNFILES_DIR", runfiles) \
                    .env("RUNFILES_MANIFEST_FILE", runfiles + "_manifest") \
                    .env("BUILD_WORKSPACE_DIRECTORY", ctx.std.env.current_dir()) \
                    .env("BUILD_WORKING_DIRECTORY", ctx.std.env.current_dir()) \
                    .args(changed_files.split("\n")) \
                    .spawn()
                exit = child.wait()

                if not exit.success:
                    out.write("\x1b[0;31mERROR\x1b[0m: format exited with code %d\n" % exit.code)

                return exit.code
    return 0

format = task(
    implementation = impl,
    args = {
        "format_target": args.string(),
    },
)
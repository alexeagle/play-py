"""
Implement a 'test' task that wraps a test command.

Improvements over 'bazel test' command:

- produce compact execution log to a tmp file
- write output locations for GitHub actions to locate artifacts
- comments on the PR thread as soon as a test failure is reported on BES
"""

TEST_FAILED="""\
:robot: Hello from Marvin! Looks like there are some failing tests!

```
{{output}}
```
"""

def try_pr_comment(ctx, template, model):
    """
    Post a comment to the PR thread.

    Failures are ignored.
    Does not attempt to update a previously posted comment.

    Args:
        ctx: the Task context
        template: the Handlebars template to use for the comment
        model: data that populates placeholders in the template
    """
    repo = ctx.std.env.var("GITHUB_REPOSITORY")
    ref_name = ctx.std.env.var("GITHUB_REF_NAME")
    if not repo or not ref_name:
        return

    temp_dir = ctx.std.env.temp_dir()
    body = temp_dir + "/comment-body.txt"
    ctx.std.fs.write(body, ctx.template.handlebars(template, data = model))
    ctx.std.process.command("gh").args([
        "pr",
        "comment",
        # https://docs.github.com/en/actions/reference/workflows-and-actions/variables
        # GITHUB_REF_NAME	The short ref name of the branch or tag that triggered the workflow run.
        # This value matches the branch or tag name shown on GitHub. For example, feature-branch-1.
        # For pull requests, the format is <pr_number>/merge.
        ref_name.split("/")[0],
        "--edit-last",
        "--create-if-none",
        "--repo", repo,
        "--body-file", body,
    ]).spawn().wait() # ignore failures

# buildifier: disable=function-docstring
def impl(ctx: task_context) -> int:
    out = ctx.std.io.stdout
    temp_dir = ctx.std.env.temp_dir()
    execlog = temp_dir + "/execlog"
    build = ctx.build(
        "//...",
        events = True,
        bazel_flags = [
            "--execution_log_compact_file=" + execlog,
            "--isatty=" + str(int(out.is_tty)),
        ],
        bazel_verb = "test",
    );
    for event in build.events():        
        if event.type == "progress":
            if event.payload.stderr.find("FAIL") != -1:
                try_pr_comment(ctx, TEST_FAILED, {"output": event.payload.stderr})

    build.wait()
    github_output = ctx.std.env.var("GITHUB_OUTPUT")
    if github_output:
        ctx.std.fs.write(github_output, "execlog=" + execlog)
    return 0

test = task(
    implementation = impl,
    args = {
        "targets": args.positional(),
    }
)
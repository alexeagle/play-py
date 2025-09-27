"""
Implement a 'build' task that wraps a build command.

Improvements over 'bazel build' command:

- customize some of the progess message text
"""

TEST_FAILED="""\
:robot: Hello from Marvin! Looks like there are some failing tests!

```
{{output}}
```
"""

def exec(command: command):
    result = command.stdout("piped").spawn().wait_with_output()
    if not result.status.success:
        print(result.stderr.strip())
        return "ERROR"
    
    return result.stdout.strip()

def try_pr_comment(ctx, template, model):
    repo = ctx.std.env.var("GITHUB_REPOSITORY")
    ref_name = ctx.std.env.var("GITHUB_REF_NAME")
    if not repo or not ref_name:
        return

    temp_dir = ctx.std.env.temp_dir()
    body = temp_dir + "/comment-body.txt"
    ctx.std.fs.write(body, ctx.template.handlebars(template, data = model))
    exec(ctx.std.process.command("gh").args([
        "pr",
        "comment",
        # https://docs.github.com/en/actions/reference/workflows-and-actions/variables
        # GITHUB_REF_NAME	The short ref name of the branch or tag that triggered the workflow run. This value matches the branch or tag name shown on GitHub. For example, feature-branch-1.
        # For pull requests, the format is <pr_number>/merge.
        ref_name.split("/")[0],
        "--repo", repo,
        "--body-file", body,
    ]))

# buildifier: disable=function-docstring
def impl(ctx: task_context) -> int:
    out = ctx.std.io.stdout
    build = ctx.build(
        "//...",
        events = True,
        bazel_flags = ["--isatty=" + str(int(out.is_tty))],
        bazel_verb = "test",
    );
    model = {}
    model["action_success_count"] = 0
    for event in build.events():        
        if event.type == "action_completed":
             if event.payload.success:
                model["action_success_count"] += 1
        if event.type == "progress":
            if event.payload.stderr.find("FAIL") != -1:
                print(event.type + ": " + str(event.payload))
                repo = ctx.std.env.var("GITHUB_REPOSITORY")
                ref_name = ctx.std.env.var("GITHUB_REF_NAME")
                if repo and ref_name:
                    try_pr_comment(ctx, TEST_FAILED, {"output": event.payload.stderr})
        # if event.type == "build_complete":
        #     print(event)

        #     model["build_completed.exit_code"] = event.payload.exit_code

    build.wait()
    return 0

test = task(
    implementation = impl,
    args = {
        "targets": args.positional(),
    }
)
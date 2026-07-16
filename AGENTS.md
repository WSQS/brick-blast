# Agent Instructions

## Code Review Mode

When asked to "review" a pull request (including bare `/oc` or `/oc review`), follow this structured review workflow using the GitHub MCP tools.

### Step 1: Gather Context

1. Call `pull_request_read` with `method: "get"` to get PR metadata (title, body, base, head).
2. Call `pull_request_read` with `method: "get_files"` to list all changed files.
3. Call `pull_request_read` with `method: "get_diff"` to get the full diff.

### Step 2: Post Inline Review Comments

For each issue found, post an **inline review comment** on the specific code line using `add_pull_request_review_comment`. Each comment must include:

- **Severity tag**: `[Critical]`, `[Major]`, `[Minor]`, or `[Nitpick]`
- **Category tag**: one of `Functional Correctness`, `Stability`, `Maintainability`, `Performance`, `Code Style`, `Security`
- **Description**: concise explanation of the issue
- **Proposed fix** (when applicable): a diff block showing the suggested change

Format for each inline comment:

```
<severity> | <category>

<description>

**Suggested fix:**

```diff
- old code
+ new code
```
```

Guidelines:
- Only comment on actionable issues. Skip trivial praise or restating the diff.
- Prefer fewer high-quality comments over many low-value ones.
- Use `subjectType: "LINE"` and provide the correct `line` number from the diff (the new line number on the RIGHT side).
- Use `path` matching the file path from the diff.
- For multi-line issues, use `startLine` and `line` together.

### Step 3: Post Summary Comment

After posting all inline comments, post a single summary comment (regular PR comment) with:

1. **Walkthrough**: a brief table grouping changes by area

```
| Area | Files | Summary |
|------|-------|---------|
| ... | ... | ... |
```

2. **Pre-merge checks**:

```
## Pre-merge Checks

- [ ] Title follows convention (`type(scope): subject`)
- [ ] Description is adequate
- [ ] No secrets or sensitive data
- [ ] CI is passing
```

3. **Overall assessment**: `REQUEST_CHANGES` or `APPROVE` with a one-sentence rationale.

### Important Notes

- All output must be in English.
- Use the GitHub MCP tools (`pull_request_read`, `add_pull_request_review_comment`) for all GitHub operations.
- The `owner`, `repo`, and `pullNumber` values come from the PR context. Use the repository you are running in.
- If the MCP tools are unavailable, fall back to a structured single-comment review with `file:line` references in the text.

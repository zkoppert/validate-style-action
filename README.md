# validate-style-action

A reusable GitHub Action that lints markdown content and pull request bodies for the following writing-style violations:

- Em-dashes (`—`) - use a hyphen with spaces ( - ) or rephrase
- The word `per` used to mean "according to" or "based on"
- Prayer/folded-hands emoji used as thanks or please
- The literal phrase `click here` as link text
- The prefix `ISP incident`
- Agentic passive voice (a model name as the subject of `made`, `wrote`, `generated`, etc.)

The linter masks fenced code blocks and inline `code` spans before scanning, so docs and instructions can legitimately quote literal rule examples without false positives.

## Why

These rules came out of personal style preferences I kept correcting on PRs, reviews, and Slack messages. Encoding them as a deterministic linter means they stop being a thing the model "should remember" and become a thing CI enforces.

## Usage

### Lint the PR body and all changed `*.md` files in a pull request

```yaml
name: Validate Style
on:
  pull_request:
    types: [opened, edited, synchronize, reopened]

jobs:
  validate-style:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
        with:
          fetch-depth: 0
      - uses: zkoppert/validate-style-action@v1
```

`fetch-depth: 0` is required so the action can diff against the PR base ref to find changed files.

### Lint a specific set of files

```yaml
- uses: zkoppert/validate-style-action@v1
  with:
    files: README.md docs/CONTRIBUTING.md
    lint-pr-body: 'false'
```

### Warn without failing the job

```yaml
- uses: zkoppert/validate-style-action@v1
  with:
    fail-on-violation: 'false'
```

## Inputs

| Name | Default | Description |
|---|---|---|
| `files` | `''` | Space-separated list of files to lint. If empty and the event is `pull_request`, defaults to changed `*.md` files in the PR. |
| `lint-pr-body` | `'true'` | When `true` on a `pull_request` event, also lints the PR body. |
| `fail-on-violation` | `'true'` | When `true`, the job fails if any violations are found. |

## Output

The action prints each violation in the standard `path:line:column` format that GitHub Actions auto-recognizes for inline annotations:

```text
✗ README.md: 2 violation(s)
  [no-em-dash] line 3:14  '—'
    Em-dash (—) is forbidden in writing on Zack's behalf. Use a regular hyphen with spaces ( - ) or rephrase.
```

Exit codes:

- `0` - no violations
- `1` - one or more violations (or non-zero from `lint.py` when `fail-on-violation` is `true`)
- `2` - missing `lint.py` or other setup error

## Local invocation

The linter can also run standalone via the CLI:

```bash
python3 lint.py README.md
echo "draft text — with an em-dash" | python3 lint.py -
python3 lint.py --json README.md
```

There are no runtime Python dependencies. Tests use the standard-library `unittest` module:

```bash
make test
```

## Development

```bash
make lint   # run the linter against itself
make test   # run unittest suite
make clean
```

## Related

This action is the canonical home for `lint.py` and `tests.py`. The same script is mirrored as a Copilot CLI skill in [`zkoppert/dotfiles`](https://github.com/zkoppert/dotfiles) under `.copilot/skills/validate-style/`, where it is invoked locally on draft text before posting. When this repo updates the linter, copy the new `lint.py` and `tests.py` into dotfiles to keep both in sync.

## License

MIT

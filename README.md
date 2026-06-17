# validate-style-action

A reusable GitHub Action that lints markdown content and pull request bodies for the following writing-style violations:

- Em-dashes (`—`): rephrase using a comma, period, parentheses, or restructure (don't substitute a spaced hyphen)
- A hyphen or en-dash used as sentence punctuation (spaced on both sides, e.g. `drift - they came in`); word-joining hyphens like `runner-up` are fine
- The word `per` used to mean "according to" or "based on"
- Prayer/folded-hands emoji used as thanks or please
- The literal phrase `click here` as link text
- The prefix `ISP incident`
- Agentic passive voice (a model name as the subject of `made`, `wrote`, `generated`, etc.)
- `This PR` / `This change` / `This commit` as a sentence subject instead of first person
- Bullets that lead with a bare past-tense action verb (`Added X`) instead of first person (`I added X`)
- References to a private or internal GitHub repo in text headed for a public surface (opt-in, behind `--check-visibility`; checks visibility through the `gh` CLI)

The linter masks fenced code blocks and inline `code` spans before scanning, so docs and instructions can legitimately quote literal rule examples without false positives.

The private-repo check is opt-in. It runs only when `lint.py` is called with `--check-visibility`, which the Action does not pass, so it never makes `gh` API calls in CI. The rule ships in `lint.py` to keep this copy byte-identical to the canonical dotfiles source.

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
    Em-dash (—) is forbidden. Rephrase using a comma, period, parentheses, or restructure the sentence. Do not substitute a spaced hyphen, which is also flagged.
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
make lint   # lint README.md, action.yml, and the entrypoint script
make test   # run unittest suite
make clean
```

## Related

The canonical source for `lint.py` and `tests.py` is the `validate-style` Copilot CLI skill in [`zkoppert/dotfiles`](https://github.com/zkoppert/dotfiles) under `.copilot/skills/validate-style/`, where it is invoked locally on draft text before posting. This repo vendors a copy so the linter can run as an Action. A `drift-check` workflow fetches the dotfiles copy on every push and pull request and fails if the two diverge. To change the linter, update the dotfiles copy first, then sync `lint.py` and `tests.py` into this repo.

## License

MIT

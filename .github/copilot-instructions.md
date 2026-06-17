# Copilot instructions for validate-style-action

This repo is the canonical home for the writing-style linter (`lint.py`) and its tests (`tests.py`). The same files are mirrored in `zkoppert/dotfiles` under `.copilot/skills/validate-style/`.

## When making changes here

1. Update `lint.py` and/or `tests.py` in this repo first - this is the source of truth.
2. Run `make lint test` and confirm everything passes.
3. Run `make test` to verify the unit suite.
4. After merging, copy the updated `lint.py` and `tests.py` into the dotfiles skill directory so local CLI invocations stay in sync.
5. Cut a new release tag (`vX.Y.Z`) so downstream `.github/workflows/` consumers can pin to it.

## Action structure

- `action.yml` is a composite action. It exposes three inputs (`files`, `lint-pr-body`, `fail-on-violation`) and shells out to `bin/validate-style-action.sh`.
- `bin/validate-style-action.sh` orchestrates file collection (explicit list, PR-diff fallback, optional PR body) and invokes `python3 lint.py`.
- `lint.py` has zero non-stdlib dependencies and exits 0 (clean) / 1 (violations) / 2 (read error).

## Security note

The PR body is passed through `env:` in `action.yml`, never inline-expanded into a shell command. Do not change that pattern - inline expansion of `${{ github.event.pull_request.body }}` is a script-injection vector.

## Style rules enforced

The linter checks for:

- em-dashes
- a hyphen or en-dash used as sentence punctuation (spaced on both sides); word-joining hyphens like `runner-up` are fine
- the word `per` used to mean "according to" or "based on"
- prayer/folded-hands emoji as thanks/please
- `click here` as link text
- `ISP incident` prefix
- agentic passive voice (model names as the subject of `made`, `wrote`, `generated`, etc.)

Code fences and inline `code` spans are masked before scanning so docs that quote rule examples don't trip the linter.

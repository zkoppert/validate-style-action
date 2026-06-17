# Copilot instructions for validate-style-action

The canonical source for the writing-style linter (`lint.py`) and its tests (`tests.py`) is the `validate-style` Copilot CLI skill in `zkoppert/dotfiles` under `.copilot/skills/validate-style/`. This repo vendors a copy so the linter can run as a GitHub Action.

## When making changes here

1. Change `lint.py` and/or `tests.py` in the dotfiles skill first; that is the source of truth.
2. Copy the updated `lint.py` and `tests.py` into this repo so the two stay byte-identical.
3. Run `make lint` and `make test` and confirm everything passes.
4. Cut a new release tag (`vX.Y.Z`) and re-point the `v1` alias so downstream `.github/workflows/` consumers pick it up.

The `drift-check` workflow fetches the dotfiles copy on every push and pull request and fails if `lint.py` or `tests.py` here diverge from it, so the two cannot silently drift apart.

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
- `This PR` / `This change` / `This commit` as a sentence subject instead of first person
- bullets that lead with a bare past-tense action verb (`Added X`) instead of first person (`I added X`)
- references to a private or internal GitHub repo in public-bound text (opt-in, behind `--check-visibility`; not run by the Action in CI)

Code fences and inline `code` spans are masked before scanning so docs that quote rule examples don't trip the linter.

#!/usr/bin/env bash
# Orchestration entrypoint for the validate-style GitHub Action.
#
# Inputs are passed via env vars (set in action.yml):
#   ACTION_PATH              - path to the action checkout
#   INPUT_FILES              - space-separated list of files (optional)
#   INPUT_LINT_PR_BODY       - 'true' to also lint the PR body
#   INPUT_FAIL_ON_VIOLATION  - 'true' to exit non-zero on violations
#   PR_BODY                  - the PR body, passed safely via env (not interpolated)
#
# The PR body is intentionally passed via env, not via inline ${{ }}
# expansion, to avoid script injection from untrusted PR contents.

set -euo pipefail

LINT_PY="${ACTION_PATH}/lint.py"

if [ ! -f "$LINT_PY" ]; then
  echo "::error::lint.py not found at $LINT_PY"
  exit 2
fi

FILES=()

# 1. Explicit file list takes precedence
if [ -n "${INPUT_FILES:-}" ]; then
  # shellcheck disable=SC2206
  FILES=($INPUT_FILES)
elif [ "${GITHUB_EVENT_NAME:-}" = "pull_request" ] || [ "${GITHUB_EVENT_NAME:-}" = "pull_request_target" ]; then
  # 2. Default for PR events: changed *.md files
  BASE_REF="${GITHUB_BASE_REF:-main}"
  git fetch origin "$BASE_REF" --depth=1 >/dev/null 2>&1 || true
  while IFS= read -r f; do
    [ -n "$f" ] && [ -f "$f" ] && FILES+=("$f")
  done < <(git diff --name-only --diff-filter=ACMR "origin/${BASE_REF}...HEAD" -- '*.md' 2>/dev/null || true)
fi

# 3. Optionally lint the PR body (as a synthetic file)
if [ "${INPUT_LINT_PR_BODY:-true}" = "true" ] && \
   { [ "${GITHUB_EVENT_NAME:-}" = "pull_request" ] || [ "${GITHUB_EVENT_NAME:-}" = "pull_request_target" ]; } && \
   [ -n "${PR_BODY:-}" ]; then
  PR_BODY_FILE="${RUNNER_TEMP:-/tmp}/pr-body.md"
  printf '%s' "$PR_BODY" > "$PR_BODY_FILE"
  FILES+=("$PR_BODY_FILE")
fi

if [ "${#FILES[@]}" -eq 0 ]; then
  echo "::notice::validate-style: no files to lint"
  exit 0
fi

echo "Linting ${#FILES[@]} file(s):"
printf '  %s\n' "${FILES[@]}"

set +e
python3 "$LINT_PY" "${FILES[@]}"
STATUS=$?
set -e

if [ "$STATUS" -eq 0 ]; then
  echo "::notice::validate-style: no violations"
  exit 0
fi

if [ "${INPUT_FAIL_ON_VIOLATION:-true}" = "false" ]; then
  echo "::warning::validate-style: violations found (fail-on-violation=false, not failing the job)"
  exit 0
fi

exit "$STATUS"

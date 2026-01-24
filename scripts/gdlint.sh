#!/bin/bash
cd "$(dirname "$0")/.." || exit 1

FIND_CMD="find . -name '*.gd'"

while IFS= read -r pattern; do
	[[ -z "$pattern" || "$pattern" =~ ^# ]] && continue
	FIND_CMD="$FIND_CMD -not -path './$pattern/*'"
done < .gdlintrcignore

eval "$FIND_CMD -print0" | xargs -0 gdlint "$@"

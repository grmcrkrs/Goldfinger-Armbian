#!/bin/sh
set -eu

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
repo_dir="$(dirname -- "$script_dir")"
failures=0

pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; failures=$((failures + 1)); }

candidate_files="$(git -C "$repo_dir" ls-files --cached --others --exclude-standard)"

if printf '%s\n' "$candidate_files" | grep -Eiq \
	'(^|/)(backups/|[^/]+\.(img|raw|dump|bin|pem|key|p12|pfx)|\.env(\..*)?)$'; then
	fail "forbidden binary, image, key, or environment filename found"
else
	pass "no forbidden artifact filenames"
fi

if rg -l --hidden --glob '!.git/**' --glob '!downloads/**' --glob '!build/**' \
	'/home/[[:alnum:]_.-]+|BEGIN (OPENSSH|RSA|EC|DSA|PGP) PRIVATE KEY' \
	"$repo_dir" >/dev/null 2>&1; then
	fail "local home path or private-key header found"
else
	pass "no local home path or private-key header"
fi

if printf '%s\n' "$candidate_files" | grep -Eiq \
	'(^|/)(backups/|[^/]*(credential|secret|token)[^/]*)'; then
	fail "sensitive filename found"
else
	pass "no backup or sensitive filenames"
fi

if git -C "$repo_dir" diff --check >/dev/null && \
	git -C "$repo_dir" diff --cached --check >/dev/null; then
	pass "Git whitespace checks"
else
	fail "Git whitespace check"
fi

printf 'SUMMARY: %s failure(s)\n' "$failures"
[ "$failures" -eq 0 ]

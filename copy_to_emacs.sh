#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
target_dir="${1:-${HOME}/.emacs.d/rime}"

if ! command -v git >/dev/null 2>&1; then
  echo "Error: git is not installed or not available in PATH." >&2
  exit 1
fi

if ! command -v rsync >/dev/null 2>&1; then
  echo "Error: rsync is not installed or not available in PATH." >&2
  exit 1
fi

if ! git -C "${repo_dir}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: ${repo_dir} is not a Git worktree." >&2
  exit 1
fi

mkdir -p "${target_dir}"
target_dir="$(cd -- "${target_dir}" && pwd -P)"

if [[ "${target_dir}" == "${repo_dir}" ]]; then
  echo "Error: the destination must differ from the source repository." >&2
  exit 1
fi

# Copy only Git-tracked static files required by Rime.
# Do not copy build artifacts, user dictionaries, installation metadata, or
# other runtime state. Existing files in the destination are never deleted.
pathspecs=(
  ':(top,glob)*.yaml'
  ':(top,glob)*.txt'
  ':(top,glob)*.gram'
  ':(top,glob)cn_dicts/**'
  ':(top,glob)en_dicts/**'
  ':(top,glob)opencc/**'
  ':(top,glob)lua/**'
)

git -C "${repo_dir}" ls-files -z -- "${pathspecs[@]}" |
  rsync -a --from0 --files-from=- "${repo_dir}/" "${target_dir}/"

echo "Copied the static Rime configuration to: ${target_dir}"
echo "User dictionaries and runtime data were left untouched."
echo "Run M-x rime-deploy in Emacs to deploy the updated configuration."

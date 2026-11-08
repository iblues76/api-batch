#!/usr/bin/env bash
# install.sh — copy api-batch into a directory on your PATH.
#
#   ./install.sh                 install or update into ~/.local/bin
#   BINDIR=/usr/local/bin ./install.sh
#   ./install.sh --uninstall
#
# api-batch is one file. On first run it creates its own Python virtual environment at
# ~/.local/share/api-batch/venv (with uv if present, else python3 -m venv) and installs the
# provider SDK there. Needs python3 (3.10+); pandoc is optional, for .docx documents.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
BINDIR="${BINDIR:-$HOME/.local/bin}"

if [ "${1:-}" = "--uninstall" ]; then
  rm -f "$BINDIR/api-batch"
  printf 'removed api-batch; your settings and projects are kept\n'
  exit 0
fi

command -v python3 >/dev/null || { printf 'python3 is required\n'; exit 1; }
mkdir -p "$BINDIR"
install -m 755 "$here/api-batch" "$BINDIR/api-batch"
printf 'installed: '; ls "$BINDIR/api-batch"
case ":$PATH:" in *":$BINDIR:"*) ;; *) printf 'note: that directory is not on your PATH\n';; esac
command -v pandoc >/dev/null || printf 'note: pandoc not found; "api-batch add" takes .md/.pdf/.png but not .docx\n'
printf 'next: api-batch -h\n'

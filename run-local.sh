#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
export JUPYTER_PATH="$PWD/.jupyter/share/jupyter${JUPYTER_PATH:+:$JUPYTER_PATH}"
exec "$PWD/.venv/bin/jupyter" lab --no-browser "$@"

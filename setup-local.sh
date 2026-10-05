#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

venv="$PWD/.venv"
if [[ ! -x "$venv/bin/python" ]]; then
  python3 -m venv --without-pip "$venv"
fi

if ! "$venv/bin/python" -m pip --version >/dev/null 2>&1; then
  pip_bootstrap="$(mktemp)"
  trap 'rm -f "$pip_bootstrap"' EXIT
  curl -fsSL https://bootstrap.pypa.io/get-pip.py -o "$pip_bootstrap"
  "$venv/bin/python" "$pip_bootstrap"
fi

"$venv/bin/python" -m pip install -r requirements-local.txt
"$venv/bin/python" -m ipykernel install \
  --prefix "$PWD/.jupyter" \
  --name gauss-local \
  --display-name "Gaussian Splat Local (.venv)"

#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
export HSA_ENABLE_DXG_DETECTION=1
export ROCM_HOME=/opt/rocm
export PYTORCH_ROCM_ARCH="${PYTORCH_ROCM_ARCH:-gfx1100}"
export MAX_JOBS="${MAX_JOBS:-2}"
export TORCH_EXTENSIONS_DIR="$PWD/.torch-extensions"
export LD_LIBRARY_PATH="$PWD/.venv-rocm/lib/python3.12/site-packages/torch/lib:/opt/rocm/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export JUPYTER_PATH="$PWD/.jupyter/share/jupyter${JUPYTER_PATH:+:$JUPYTER_PATH}"
exec "$PWD/.venv-rocm/bin/jupyter" lab --no-browser "$@"

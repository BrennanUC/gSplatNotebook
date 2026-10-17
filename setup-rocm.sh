#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

for command in python3.12 git curl c++; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing prerequisite: $command. See LOCAL_SETUP.md." >&2
    exit 1
  fi
done
if [[ ! -x /opt/rocm/bin/hipcc ]]; then
  echo "Install the ROCm 7.2 development tools at /opt/rocm first. See LOCAL_SETUP.md." >&2
  exit 1
fi
python3.12 -c 'import platform, sys; sys.exit(0 if platform.machine() == "x86_64" else "The AMD wheels require x86_64.")'

venv="$PWD/.venv-rocm"
gsplat_commit=2a907639c1777c68f48c4a792232714d8e8cb854

if [[ -e gsplat ]]; then
  if [[ ! -d gsplat/.git ]] || \
     [[ "$(git -C gsplat rev-parse HEAD)" != "$gsplat_commit" ]] || \
     [[ -n "$(git -C gsplat status --porcelain)" ]]; then
    echo "gsplat already exists and is not a clean checkout of $gsplat_commit." >&2
    echo "Move it aside before rerunning setup; existing files were preserved." >&2
    exit 1
  fi
fi

if [[ ! -x "$venv/bin/python" ]]; then
  python3.12 -m venv --without-pip "$venv"
fi
"$venv/bin/python" -c 'import sys; sys.exit(0 if sys.version_info[:2] == (3, 12) else ".venv-rocm must use Python 3.12.")'
if ! "$venv/bin/python" -m pip --version >/dev/null 2>&1; then
  pip_bootstrap="$(mktemp)"
  trap 'rm -f "$pip_bootstrap"' EXIT
  curl -fsSL https://bootstrap.pypa.io/get-pip.py -o "$pip_bootstrap"
  "$venv/bin/python" "$pip_bootstrap"
fi
"$venv/bin/python" -m pip install --upgrade pip setuptools wheel

# AMD's Python 3.12 / ROCm 7.2 wheels, as documented at:
# https://rocm.docs.amd.com/projects/radeon-ryzen/en/docs-7.2/docs/install/installrad/wsl/install-pytorch.html
wheel_base=https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2
"$venv/bin/python" -m pip install 'numpy==1.26.4' \
  "$wheel_base/torch-2.9.1%2Brocm7.2.0.lw.git7e1940d4-cp312-cp312-linux_x86_64.whl" \
  "$wheel_base/torchvision-0.24.0%2Brocm7.2.0.gitb919bd0c-cp312-cp312-linux_x86_64.whl" \
  "$wheel_base/triton-3.5.1%2Brocm7.2.0.gita272dfa8-cp312-cp312-linux_x86_64.whl" \
  "$wheel_base/torchaudio-2.9.0%2Brocm7.2.0.gite3c6ee2b-cp312-cp312-linux_x86_64.whl"

export HSA_ENABLE_DXG_DETECTION=1
export ROCM_HOME=/opt/rocm
export PYTORCH_ROCM_ARCH="${PYTORCH_ROCM_ARCH:-gfx1100}"
export MAX_JOBS="${MAX_JOBS:-2}"
export TORCH_EXTENSIONS_DIR="$PWD/.torch-extensions"
export LD_LIBRARY_PATH="$venv/lib/python3.12/site-packages/torch/lib:/opt/rocm/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# On WSL use the system HSA runtime, per AMD's installation instructions.
# Only remove bundled runtime files inside this project's virtual environment.
if [[ -e /usr/lib/wsl/lib/libdxcore.so ]]; then
  "$venv/bin/python" - <<'PY'
import sysconfig
from pathlib import Path

torch_lib = Path(sysconfig.get_path("purelib")) / "torch" / "lib"
for runtime in torch_lib.glob("libhsa-runtime64.so*"):
    runtime.unlink()
PY
fi

"$venv/bin/python" -m pip install -r requirements-rocm.txt
"$venv/bin/python" - <<'PY'
import torch

if not torch.version.hip or not torch.cuda.is_available():
    raise SystemExit("ROCm PyTorch cannot access the GPU. Check the driver/runtime in LOCAL_SETUP.md.")
print(f"PyTorch {torch.__version__}; HIP {torch.version.hip}; GPU: {torch.cuda.get_device_name(0)}")
PY

if [[ ! -e gsplat ]]; then
  git clone --no-checkout https://github.com/HPC-Ken/gsplat.git gsplat
  git -C gsplat checkout --detach "$gsplat_commit"
fi
git -C gsplat submodule update --init --recursive
# Defer native HIP compilation to first use, keeping source available for JIT.
BUILD_NO_HIP=1 "$venv/bin/python" -m pip install --no-build-isolation --no-deps -e ./gsplat
"$venv/bin/python" -m ipykernel install \
  --prefix "$PWD/.jupyter" \
  --name gauss-rocm \
  --display-name "Gaussian Splat ROCm (RX 7900 XT)"
"$venv/bin/python" -m pip check
echo "ROCm setup complete. Start Jupyter with: bash run-rocm.sh"

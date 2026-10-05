# Local Gaussian Splat Pipeline

This checkout contains the notebook and environment setup scripts. Python
environments, the gsplat source, input video, and trained outputs are downloaded
or generated locally; they are not included in Git.

## Prerequisites

- Ubuntu/WSL2 with Python 3.12, Git, curl, and internet access.
- For AMD training: an RX 7900 XT (`gfx1100`), a compatible Windows WSL driver,
  and the ROCm 7.2 development tools at `/opt/rocm`, including `hipcc`.
  Follow [AMD's WSL installation instructions](https://rocm.docs.amd.com/projects/radeon-ryzen/en/docs-7.2/docs/install/installrad/wsl/install-radeon.html)
  to install the driver/runtime before using this project. The setup script
  installs Python packages, not system drivers.
- Your own video, named `drone-review.mp4` beside the notebook, or a different
  `VIDEO_PATH` in the configuration cell.

## CPU preprocessing

From the project folder:

```bash
bash setup-local.sh
bash run-local.sh
```

Open `SmallScaleGaussianSplat_Colab_Ready.ipynb` and select
**Gaussian Splat Local (.venv)**. This environment supports video extraction,
COLMAP reconstruction, and dataset preparation (sections 1–15). FFmpeg is
provided by `imageio-ffmpeg` when a system FFmpeg is unavailable. GPU training
needs the environment below.

## AMD GPU training

After installing the ROCm system prerequisites:

```bash
bash setup-rocm.sh
bash run-rocm.sh
```

Select **Gaussian Splat ROCm (RX 7900 XT)**, then run the notebook cells in order.
The installer creates `.venv-rocm`, installs AMD's matching PyTorch 2.9.1 and
torchvision wheels, and downloads a pinned
[gsplat Radeon HIP port](https://github.com/HPC-Ken/gsplat/tree/2a907639c1777c68f48c4a792232714d8e8cb854).
The launcher supplies the WSL library paths, GPU architecture, and local
extension cache. Native kernels compile on first use; the first training run
will take longer to start. This gsplat port is experimental.

The ROCm setup targets Python 3.12 / ROCm 7.2 / `gfx1100`. Other GPU architectures
and NVIDIA setups require their own compatible runtime and gsplat installation.
The notebook also has a Colab installation path; that path is separate from
these local scripts.

## Input and output

Place the source video beside the notebook before running it. Outputs go under
`gaussian_splat/`, with training checkpoints and exported `.ply` files under
`gaussian_splat/trained/`. No source video or previous reconstruction is included.

The current configuration uses 24 extracted frames per second, the full video,
and 40,000 training steps. For an initial small run, set `MAX_FRAMES = 100`,
`IMAGE_WIDTH = 1280`, `NUM_ITERATIONS = 2000`, and `SH_DEGREE = 3` before running
the extraction and training cells. Reconstruction quality depends on the
video's texture, overlap, and camera motion.

## Setup checks

```bash
.venv/bin/python -m pip check
.venv-rocm/bin/python -m pip check
```

The ROCm installer checks whether PyTorch can access the GPU. Notebook section 18
checks that the gsplat trainer imports successfully. Full pipeline validation
requires a video; successful package installation alone does not verify a
reconstruction or GPU rasterization.

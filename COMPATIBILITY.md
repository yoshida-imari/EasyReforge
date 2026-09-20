# reForge 739b2e1 compatibility notes

## Upstream baseline

- Repository: `Panchovix/stable-diffusion-webui-reForge`
- Branch: `main`
- Commit: `739b2e1d9ab63160eaff9c8f73172c8da68424e1`
- GPU baseline: GeForce RTX 4080 (Ada, `sm89`)
- Runtime baseline: Python 3.10, PyTorch 2.9.0, CUDA 12.8

EasyReforge no longer replaces these upstream files:

- `extensions-builtin/forge_preprocessor_inpaint/scripts/preprocessor_inpaint.py`
- `ldm_patched/modules/utils.py`
- `requirements_versions.txt`

The two EasyReforge-only NoobAI preprocessors now live in
`extensions-builtin/easyreforge_preprocessor_noobai`. This keeps reForge's
`PreprocessorInpaintNoobAIXL` and its current sampler callback API intact.

## `set_attr` investigation

The target commit's `ldm_patched/modules/utils.py:set_attr()` does **not** have
an `obj is None` check. This upgrade therefore does not assume that every cause
of a `None` traversal was removed upstream. Instead, the standard WebUI startup
path installs a guarded implementation before model loading and extension
scripts run:

1. `webui.py` calls `initialize.imports()` and then
   `initialize.initialize()`.
2. `modules/initialize.py:initialize()` imports `modules.sd_models` before
   loading scripts or scheduling the initial model load.
3. Importing `modules/sd_models.py` saves the original functions and replaces
   `ldm_patched.modules.utils.set_attr` and `set_attr_param` with
   `safer_set_attr` and `safer_set_attr_param`. These replacements reject a
   `None` object, a missing intermediate attribute, and a `None` parameter
   value, and return the previous object when replacement succeeds.

The relevant callers at this commit are:

- `ldm_patched/modules/controlnet.py:ControlLora.pre_run()` uses
  `set_attr_param` while constructing its ControlNet module. The first copy
  loop has a local exception guard; the second relies on the runtime
  `modules.sd_models` replacement for missing/`None` paths.
- `ldm_patched/modules/model_patcher.py:ModelPatcher.patch_model()` stores the
  return value of `set_attr` in `object_patches_backup`, and
  `unpatch_model()` restores it. The current return-previous-object contract is
  therefore required for model patching and model switching.
- `ldm_patched/helpers/torch_compile.py:apply_torch_compile_wrapper()` first
  validates each path with `get_attr`, replaces it with `set_attr`, and restores
  the saved object in `finally`.

The old EasyReforge `utils.py` returned no previous object and replaced values
with `torch.nn.Parameter` even in generic `set_attr`. Reapplying that whole file
would regress `ModelPatcher` backup/restore behavior, so no overlay is retained.
A nonstandard process that calls `ldm_patched.modules.utils.set_attr` without
first importing `modules.sd_models` would still use the unguarded upstream
implementation; this residual risk is covered by the ControlNet and repeated
model-switch tests in `TESTING.md`.

## Dependency decisions

| Package | Version/source | Reason |
| --- | --- | --- |
| torch | `2.9.0+cu128` | reForge target baseline |
| torchvision | `0.24.0+cu128` | Official pair for torch 2.9.0 |
| torchaudio | `2.9.0+cu128` | Kept on the same release/CUDA line |
| triton-windows | `3.5.1.post24` | Triton 3.5 is the PyTorch 2.9 line |
| SageAttention | `2.2.0+cu128torch2.9.0andhigher.post4` | ABI3 Windows wheel for CUDA 12.8 and torch 2.9+ |
| diffusers | `0.32.2` | Matches upstream `requirements_versions.txt` |
| transformers | `4.48.1` | Matches upstream |
| huggingface_hub | `0.25.0` | Matches upstream |
| pydantic | reForge `1.10.15` fix wheel | Matches upstream |
| gradio | `3.41.2` | Matches upstream/UI API |
| protobuf | `3.20.0` | Matches upstream |

`requirements_versions.txt` is deliberately not shipped in the overlay. The
copy step therefore preserves the file checked out by reForge. The additional
EasyReforge requirements use the same versions for overlapping core packages.
The unrelated `onnx` package was removed from the old environment freeze because
ONNX 1.17 requires protobuf 3.20.2 or newer; WD14 uses `onnxruntime` directly.

## Extension audit

No extension repository SHA was advanced in this upgrade. The 16 enabled fixed
commits compile on Python 3.10 and their mandatory reForge module imports still
exist at the target commit. Two extensions remain intentionally moved to
`extensions-backup`, as before.

| Extension | Status for this upgrade |
| --- | --- |
| a1111-sd-webui-tagcomplete | Fixed SHA retained |
| ADetailer | Fixed SHA retained; installer overlay pins MediaPipe 0.10.11 |
| reForge-Sigmas_merge | Fixed SHA retained |
| sd-dynamic-prompts | Fixed SHA retained |
| sd-forge-couple | Fixed SHA retained; missing ForgeCanvas import is optional and guarded |
| sdweb-easy-generate-forever | Fixed SHA retained |
| sd-webui-ar | Still moved to backup |
| --sd-webui-ar-plusplus | Fixed SHA retained |
| sd-webui-cd-tuner | Fixed SHA retained |
| sd-webui-lora-block-weight | Fixed SHA retained |
| sd-webui-lora-block-weight-reforge | Still moved to backup |
| sd-webui-negpip | Fixed SHA retained |
| sd-webui-pnginfo-beautify | Fixed SHA retained |
| sd-webui-weight-helper | Fixed SHA retained |
| Stable-Diffusion-Webui-Civitai-Helper | Fixed SHA retained |
| stable-diffusion-webui-wd14-tagger | Fixed SHA retained; ONNX-focused requirements overlay |
| z-tipo-extension | Fixed SHA retained |
| stable-diffusion-webui-localization-ja_JP | Fixed SHA retained |

ADetailer's pinned installer requests MediaPipe 0.10.13 or newer, which requires
protobuf 4.25.3 or newer. MediaPipe 0.10.11 provides a CPython 3.10 Windows wheel
and retains the protobuf 3.x dependency line, so the installer overlay uses it.

WD14 Tagger's pinned requirements unconditionally install TensorFlow and
DeepDanbooru. EasyReforge uses the ONNX tagger path, while recent TensorFlow
requirements conflict with reForge's protobuf pin. The requirements overlay
therefore keeps the ONNX/UI dependencies and leaves the optional DeepDanbooru
backend uninstalled.

## Known compatibility risks

- The two NoobAI preprocessors are migrated to the target callback API, but
  image quality and mask-boundary behavior require the GPU tests in `TESTING.md`.
- `inpaint_only_noobai_xl+lama` downloads `ControlNetLama.pth` on first use.
- ADetailer MediaPipe detectors use an older compatible MediaPipe release;
  normal Ultralytics/YOLO ADetailer operation is the primary supported path.
- WD14's ONNX path is retained. Its optional TensorFlow/DeepDanbooru path is not
  part of this dependency set and is unverified.
- TIPO still uses the existing CUDA 12.4 llama-cpp-python wheel. It is separate
  from PyTorch's CUDA runtime, but it needs a Windows GPU smoke test.
- SageAttention and Triton require a sufficiently recent NVIDIA driver and a
  real RTX 4080 test; static and dependency checks cannot execute their kernels.

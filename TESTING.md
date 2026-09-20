# Windows test plan for reForge 739b2e1

Run these tests on Windows with the EasyReforge Python 3.10 environment and an
RTX 4080. Do not place generated images or downloaded model files under Git.

## Installation without model downloads

1. From the EasyReforge root, run `EasyReforge\Update_DisableMinimumDownload.bat`.
2. Run `Update.bat`.
3. Confirm the installer does not run `NoobAiCommon_Minimum.bat`.
4. Confirm the reForge checkout is still at the requested commit:

   ```bat
   git -C stable-diffusion-webui-reForge rev-parse HEAD
   ```

   Expected: `739b2e1d9ab63160eaff9c8f73172c8da68424e1`.

5. Run `Update.bat` a second time and repeat the SHA check. It must not return to
   `19395bf96ccdc605774c76a9fe8cc7145b637128`.
6. Activate the installed environment and verify dependencies:

   ```bat
   call EasyTools\Python\Python_Activate.bat
   python -m pip check
   python -c "import torch, torchvision, triton; print(torch.__version__, torch.version.cuda, torchvision.__version__, triton.__version__)"
   python -c "import diffusers, transformers, huggingface_hub, pydantic, gradio, google.protobuf; print(diffusers.__version__, transformers.__version__, huggingface_hub.__version__, pydantic.__version__, gradio.__version__, google.protobuf.__version__)"
   ```

   Expected core versions: torch 2.9.0+cu128, CUDA 12.8, torchvision
   0.24.0+cu128, Triton 3.5.1, diffusers 0.32.2, transformers 4.48.1,
   huggingface_hub 0.25.0, pydantic 1.10.15, gradio 3.41.2, protobuf
   3.20.0.

7. Confirm `Model` junctions, `OutputReforge`, ControlNet presets, Japanese
   localization, `styles.csv`, and the existing `config.json`/styles backup
   behavior are present after the repeated update.

## Static checks

From the repository root:

```bat
EasyTools\Python\env\python310\python.exe -m py_compile EasyReforge\Reforge\src\adetailer_install.py EasyReforge\Reforge\src\reforge_update_config.py EasyReforge\Reforge\src\reforge_update_ui-config.py EasyReforge\Reforge\src\stable-diffusion-webui-reForge\extensions-builtin\easyreforge_preprocessor_noobai\scripts\preprocessor_noobai.py
git diff --check
git status --short
```

Inspect the echoed commands in `Reforge.bat`, `ReforgeExtension.bat`,
`ReforgeLink.bat`, and `Update.bat`. In particular, confirm quoted paths resolve
under the EasyReforge root and `%*` remains forwarded by the launch wrappers.

## WebUI and generation tests

Record the command, console log, elapsed time, peak VRAM, and output image for
each test. Use a known-good NoobAI Epsilon model and fixed seed unless noted.

1. **WebUI startup** — Run `Reforge.bat`. Confirm no extension import failure,
   no repeated core dependency reinstall, Japanese UI availability, and the
   target reForge commit in the startup log.
2. **NoobE 896x1152** — Generate one image at width 896 and height 1152.
   Confirm dimensions, metadata, VAE decode, and normal completion.
3. **Hires.fix 1.5x** — Repeat with Hires.fix enabled at 1.5 upscale. Confirm
   the final size and that the second pass completes without NaNs or OOM.
4. **LoRA** — Apply a known-good NoobE LoRA and compare against the same seed
   without it. Confirm the LoRA appears in metadata and changes the result.
5. **TIPO** — Enable the TIPO script, generate once, and confirm generated tags
   and llama-cpp initialization without dependency changes.
6. **ADetailer** — Use a bundled YOLO face model. Confirm detection, mask
   preview, inpaint pass, and final output. MediaPipe detectors are secondary;
   if tested, record that MediaPipe 0.10.11 is loaded.
7. **Noob Inpaint** — In ControlNet/Inpaint, test both
   `inpaint_only_noobai_xl` and `inpaint_only_noobai_xl+lama`. Confirm the
   unmasked region is preserved, the mask is filled, and the LaMa variant has no
   visible tile seam. The first LaMa run is expected to download its annotator
   model.
8. **ControlNet** — Load each retained preset relevant to NoobE, especially
   `Noob_Inpaint` and `Noob_Tile`, and complete a generation with its matching
   ControlNet model.
9. **Repeated generation/model switch** — Generate several batches, switch to
   a second checkpoint, generate again, then switch back. Confirm no stale LoRA,
   `NoneType`, allocation, or object-patch restoration error.
10. **SageAttention** — Run `Reforge_Fast.bat`. Confirm the log selects
    SageAttention, Triton compiles a kernel, and generation completes without a
    fallback or a torch 2.7 wheel being installed.

## Result record

| Test | Pass/fail | Notes/log path |
| --- | --- | --- |
| Update twice / SHA retained |  |  |
| WebUI startup |  |  |
| NoobE 896x1152 |  |  |
| Hires.fix 1.5x |  |  |
| LoRA |  |  |
| TIPO |  |  |
| ADetailer |  |  |
| Noob Inpaint |  |  |
| ControlNet |  |  |
| Repeated generation/model switch |  |  |
| Reforge_Fast / SageAttention |  |  |

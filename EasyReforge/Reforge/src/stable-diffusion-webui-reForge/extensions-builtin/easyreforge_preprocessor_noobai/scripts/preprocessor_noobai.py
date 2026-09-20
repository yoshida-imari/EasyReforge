import os

import cv2
import numpy as np
import torch
import yaml
from omegaconf import OmegaConf

from annotator.lama.saicinpainting.training.trainers import load_checkpoint
from modules.paths_internal import extensions_builtin_dir
from modules.modelloader import load_file_from_url
from modules_forge.shared import add_supported_preprocessor, preprocessor_dir
from modules_forge.supported_preprocessor import Preprocessor, PreprocessorParameter


class PreprocessorInpaintOnlyNoobAIXL(Preprocessor):
    """NoobAI XL inpaint-only behavior without replacing reForge's preprocessor."""

    def __init__(self):
        super().__init__()
        self.name = "inpaint_only_noobai_xl"
        self.tags = ["Inpaint"]
        self.model_filename_filters = ["inpaint", "noobai"]
        self.slider_resolution = PreprocessorParameter(visible=False)
        self.fill_mask_with_one_when_resize_and_fill = True
        self.expand_mask_when_resize_and_fill = True
        self.image = None
        self.mask = None
        self.latent = None

    def __call__(
        self,
        input_image,
        resolution=512,
        slider_1=None,
        slider_2=None,
        slider_3=None,
        input_mask=None,
        **kwargs,
    ):
        if input_mask is None:
            return input_image

        image = np.asarray(input_image).copy()
        mask = np.asarray(input_mask).astype(np.float32) / 255.0
        mask = mask > 0.5
        if mask.ndim == 2:
            mask = mask[..., None]
        if mask.shape[-1] == 1:
            mask = np.repeat(mask, image.shape[-1], axis=-1)
        image[mask] = 0
        return image

    def process_before_every_sampling(self, process, cond, mask, *args, **kwargs):
        self.image = cond
        self.mask = mask.round()
        latent_sampling_mask = mask.ceil()

        vae = process.sd_model.forge_objects.vae
        latent_image = vae.encode(self.image.movedim(1, -1))
        latent_image = process.sd_model.forge_objects.unet.model.latent_format.process_in(latent_image)
        _, _, height, width = latent_image.shape

        latent_mask = torch.nn.functional.interpolate(
            latent_sampling_mask, size=(height * 8, width * 8), mode="bilinear"
        ).round()
        latent_mask = torch.nn.functional.max_pool2d(latent_mask, (8, 8)).round().to(latent_image)

        unet = process.sd_model.forge_objects.unet.clone()

        def pre_cfg(cfg_args):
            latent_input = cfg_args["input"]
            timestep = cfg_args["timestep"]
            noisy_latent = latent_image.to(latent_input) + timestep[:, None, None, None].to(
                latent_input
            ) * torch.randn_like(latent_image).to(latent_input)
            cfg_args["input"] = latent_input * latent_mask.to(latent_input) + noisy_latent * (
                1.0 - latent_mask.to(latent_input)
            )
            return cfg_args["conds_out"]

        def post_cfg(cfg_args):
            denoised = cfg_args["denoised"]
            return denoised * latent_mask.to(denoised) + latent_image.to(denoised) * (
                1.0 - latent_mask.to(denoised)
            )

        unet.set_model_sampler_pre_cfg_function(pre_cfg)
        unet.set_model_sampler_post_cfg_function(post_cfg)
        process.sd_model.forge_objects.unet = unet
        self.latent = latent_image

        mixed_cond = cond.clone() * (1.0 - self.mask)
        return mixed_cond, None

    def _blend_generated_result(self, image):
        sigma = 3
        mask = self.mask[0, 0].detach().cpu().numpy().astype(np.float32)
        mask = cv2.dilate(mask, np.ones((sigma, sigma), dtype=np.uint8))
        mask = cv2.blur(mask, (sigma, sigma))[None]
        mask = torch.from_numpy(np.ascontiguousarray(mask)).to(image).clip(0, 1)
        raw = self.image[0].to(image).clip(0, 1)
        return raw * (1.0 - mask) + image.clip(0, 1) * mask

    def process_after_every_sampling(self, process, params, *args, **kwargs):
        batch_result = args[0]
        batch_result.images = [self._blend_generated_result(image) for image in batch_result.images]


class PreprocessorInpaintOnlyNoobAIXLLama(PreprocessorInpaintOnlyNoobAIXL):
    """NoobAI XL inpaint-only processing with LaMa applied to the mask boundary."""

    def __init__(self):
        super().__init__()
        self.name = "inpaint_only_noobai_xl+lama"
        self.boundary_width = 7
        self.tile_size = 2048
        self.model_loaded = False

    def load_model(self):
        if self.model_loaded:
            return

        model_path = load_file_from_url(
            "https://huggingface.co/lllyasviel/Annotators/resolve/main/ControlNetLama.pth",
            model_dir=preprocessor_dir,
        )
        config_path = os.path.join(
            extensions_builtin_dir,
            "forge_preprocessor_inpaint",
            "scripts",
            "lama_config.yaml",
        )
        with open(config_path, "rt", encoding="utf-8") as config_file:
            config = OmegaConf.create(yaml.safe_load(config_file))
        config.training_model.predict_only = True
        config.visualizer.kind = "noop"
        model = load_checkpoint(
            config,
            os.path.abspath(model_path),
            strict=False,
            map_location="cpu",
        )
        self.setup_model_patcher(model)
        self.model_loaded = True

    def _process_lama_tile(self, image, mask, x, y):
        tile_image = image[y : y + self.tile_size, x : x + self.tile_size]
        tile_mask = mask[y : y + self.tile_size, x : x + self.tile_size]
        if tile_image.size == 0 or not np.any(tile_mask):
            return tile_image

        color = np.ascontiguousarray(tile_image).astype(np.float32) / 255.0
        mask_tensor = torch.from_numpy(np.ascontiguousarray(tile_mask).astype(np.float32))

        with torch.no_grad():
            color_tensor = self.send_tensor_to_model_device(torch.from_numpy(color))
            mask_tensor = self.send_tensor_to_model_device(mask_tensor)
            mask_tensor = (mask_tensor > 0.5).float()
            mask_hwc = mask_tensor[..., None]
            image_feed = torch.cat(
                [color_tensor * (1.0 - mask_hwc), mask_hwc], dim=-1
            ).permute(2, 0, 1)[None]
            prediction = self.model_patcher.model(image_feed)[0].permute(1, 2, 0)
            prediction = prediction * mask_hwc + color_tensor * (1.0 - mask_hwc)

        return (prediction * 255.0).detach().cpu().numpy().clip(0, 255).astype(np.uint8)

    def _apply_lama_to_boundary(self, image, original_mask):
        self.load_model()
        self.move_all_model_patchers_to_gpu()

        binary_mask = np.asarray(original_mask)
        if binary_mask.ndim == 3:
            binary_mask = binary_mask[..., 0]
        binary_mask = (binary_mask > 0).astype(np.uint8)
        kernel = np.ones((self.boundary_width, self.boundary_width), dtype=np.uint8)
        boundary = cv2.dilate(binary_mask, kernel) - cv2.erode(binary_mask, kernel)
        if not np.any(boundary):
            return image

        result = image.copy()
        height, width = image.shape[:2]
        for y in range(0, height, self.tile_size):
            for x in range(0, width, self.tile_size):
                tile_mask = boundary[y : y + self.tile_size, x : x + self.tile_size]
                if not np.any(tile_mask):
                    continue
                tile = self._process_lama_tile(image, boundary, x, y)
                tile_height, tile_width = tile.shape[:2]
                result[y : y + tile_height, x : x + tile_width] = tile
        return result

    def process_after_every_sampling(self, process, params, *args, **kwargs):
        batch_result = args[0]
        original_mask = self.mask[0, 0].detach().cpu().numpy()
        processed_images = []

        for image in batch_result.images:
            blended = self._blend_generated_result(image)
            blended_numpy = (
                blended.permute(1, 2, 0).detach().cpu().numpy() * 255.0
            ).clip(0, 255).astype(np.uint8)
            processed = self._apply_lama_to_boundary(blended_numpy, original_mask)
            processed_tensor = torch.from_numpy(processed).float().permute(2, 0, 1) / 255.0
            processed_images.append(processed_tensor.to(image.device, dtype=image.dtype))

        batch_result.images = processed_images


add_supported_preprocessor(PreprocessorInpaintOnlyNoobAIXL())
add_supported_preprocessor(PreprocessorInpaintOnlyNoobAIXLLama())

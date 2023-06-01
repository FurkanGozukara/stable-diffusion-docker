# Docker image for Stable Diffusion WebUI and Dreambooth extension

## Installs

* Ubuntu 22.04 LTS
* CUDA 11.8
* Python 3.10.6
* [Automatic1111 Stable Diffusion Web UI](
  https://github.com/AUTOMATIC1111/stable-diffusion-webui.git) 1.3.0
* [Dreambooth extension](
  https://github.com/d8ahazard/sd_dreambooth_extension) (dev branch)
* [Deforum extension](
  https://github.com/deforum-art/sd-webui-deforum)
* [ControlNet extension](
  https://github.com/Mikubill/sd-webui-controlnet) v1.1.206
* Torch 2.0.1
* xformers 0.0.20 (disabled by default)
* v1-5-pruned.safetensors
* vae-ft-mse-840000-ema-pruned.safetensors

## Credits

1. [RunPod](https://www.runpod.io/) for providing most
   of the [container](https://github.com/runpod/containers) code.
2. Dr. Furkan Gözükara for his amazing
   [YouTube videos](https://www.youtube.com/@SECourses/videos]).
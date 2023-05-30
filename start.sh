#!/usr/bin/env bash
echo "Container Started"
export PYTHONUNBUFFERED=1
source /venv/bin/activate

if [[ ${INSTALL_MODELS} ]]
then
    echo "Download Stable Diffusion model"
    cd /home/ubuntu/stable-diffusion-webui/models/Stable-diffusion
    wget https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned.safetensors

    echo "Download Stable Diffusion VAE"
    cd /home/ubuntu/stable-diffusion-webui/models/VAE
    wget https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.safetensors
fi

if [[ ${RUNPOD_STOP_AUTO} ]]
then
    echo "Skipping auto-start of Web UI"
else
    echo "Started Web UI through launcher script"
    cd /workspace/stable-diffusion-webui
    python launcher.py &
fi

if [[ ${PUBLIC_KEY} ]]
then
    echo "Installing SSH public key"
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    cd ~/.ssh
    echo ${PUBLIC_KEY} >> authorized_keys
    chmod 700 -R ~/.ssh
    cd /
    service ssh start
    echo "SSH Service Started"
fi

if [[ ${JUPYTER_PASSWORD} ]]
then
    echo "Starting Jupyter lab"
    ln -sf /examples /workspace
    ln -sf /root/welcome.ipynb /workspace

    cd /
    jupyter lab --allow-root --no-browser --port=8888 --ip=* \
        --ServerApp.terminado_settings='{"shell_command":["/bin/bash"]}' \
        --ServerApp.token=${JUPYTER_PASSWORD} --ServerApp.allow_origin=* --ServerApp.preferred_dir=/workspace
    echo "Jupyter Lab Started"
fi

sleep infinity
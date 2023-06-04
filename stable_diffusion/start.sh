#!/usr/bin/env bash
export MAIN_VEV=/workspace/venv
export KOHYA_VEV=/workspace/kohya_ss/venv
export PYTHONUNBUFFERED=1

echo "Container is running"

# Sync venv to workspace to support Network volumes
echo "Syncing venv to workspace, please wait..."
rsync -au --remove-source-files /venv/ /workspace/venv/
rm -rf /venv

# Sync Web UI to workspace to support Network volumes
echo "Syncing Stable Diffusion Web UI to workspace, please wait..."
rsync -au --remove-source-files /stable-diffusion-webui/ /workspace/stable-diffusion-webui/
rm -rf /stable-diffusion-webui

# Sync Kohya_ss to workspace to support Network volumes
echo "Syncing Kohya_ss to workspace, please wait..."
rsync -au --remove-source-files /kohya_ss/ /workspace/kohya_ss/
rm -rf /kohya_ss

ln -s /sd-models/v1-5-pruned.safetensors /workspace/stable-diffusion-webui/models/Stable-diffusion/v1-5-pruned.safetensors
ln -s /sd-models/vae-ft-mse-840000-ema-pruned.safetensors workspace/stable-diffusion-webui/models/VAE/vae-ft-mse-840000-ema-pruned.safetensors

if [[ ${PUBLIC_KEY} ]]
then
    echo "Installing SSH public key"
    mkdir -p ~/.ssh
    echo ${PUBLIC_KEY} >> ~/.ssh/authorized_keys
    chmod 700 -R ~/.ssh
    service ssh start
    echo "SSH Service Started"
fi

if [[ ${JUPYTER_PASSWORD} ]]
then
    echo "Starting Jupyter lab"
    ln -sf /examples /workspace
    ln -sf /root/welcome.ipynb /workspace

    cd /
    nohup jupyter lab --allow-root \
        --no-browser \
        --port=8888 \
        --ip=* \
        --ServerApp.terminado_settings='{"shell_command":["/bin/bash"]}' \
        --ServerApp.token=${JUPYTER_PASSWORD} \
        --ServerApp.allow_origin=* \
        --ServerApp.preferred_dir=/workspace &
    echo "Jupyter Lab Started"
fi

if [[ ${DISABLE_AUTOLAUNCH} ]]
then
    echo "Auto launching is disabled so the applications not be started automatically"
    echo "You can launch them manually using the launcher scripts:"
    echo ""
    echo "   Stable Diffusion Web UI:"
    echo "   ---------------------------------------------"
    echo "   cd /workspace/stable-diffusion-webui"
    echo "   deactivate && source /workspace/venv/activate"
    echo "   ./webui.sh -f"
    echo ""
    echo "   Kohya_ss"
    echo "   ---------------------------------------------"
    echo "   cd /workspace/kohya_ss"
    echo "   deactivate"
    echo "   ./gui.sh --listen 0.0.0.0 --server_port 3010"
else
    mkdir -p /workspace/logs
    echo "Starting Stable Diffusion Web UI"
    source ${MAIN_VEV}/bin/activate
    cd /workspace/stable-diffusion-webui && nohup ./webui.sh -f > /workspace/logs/webui.log &
    echo "Stable Diffusion Web UI started"
    echo "Log file: /workspace/logs/webui.log"
    deactivate

    echo "Starting Kohya_ss Web UI"
    source ${KOHYA_VEV}/bin/activate
    cd /workspace/kohya_ss && nohup ./gui.sh --listen 0.0.0.0 --headless --server_port 3010 > /workspace/logs/kohya_ss.log &
    echo "Kohya_ss started"
    echo "Log file: /workspace/logs/kohya_ss.log"
    deactivate
fi

if [ ${ENABLE_TENSORBOARD} ]; then
    echo "Starting Tensorboard"
    cd /workspace
    mkdir -p /workspace/logs/ti
    mkdir -p /workspace/logs/dreambooth
    ln -s /workspace/stable-diffusion-webui/models/dreambooth /workspace/logs/dreambooth
    ln -s /workspace/stable-diffusion-webui/textual_inversion /workspace/logs/ti
    source ${MAIN_VEV}/bin/activate
    nohup tensorboard --logdir=/workspace/logs --port=6006 --host=0.0.0.0 &
    deactivate
    echo "Tensorboard Started"
fi

echo "All services have been started"

sleep infinity
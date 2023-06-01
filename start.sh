#!/usr/bin/env bash
echo "Container Started"
export PYTHONUNBUFFERED=1
source /venv/bin/activate

echo "Syncing venv to workspace, please wait..."
rsync -au --remove-source-files /venv/ /workspace/venv/

echo "Syncing stable diffusion to workspace, please wait..."
rsync -au --remove-source-files /stable-diffusion-webui/ /workspace/stable-diffusion-webui/

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
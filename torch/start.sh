#!/usr/bin/env bash

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

echo "Container Started"

sleep infinity
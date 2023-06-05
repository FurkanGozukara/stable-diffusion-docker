ARG BASE_IMAGE=nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04
FROM ${BASE_IMAGE} as dev-base

# Create workspace working directory
WORKDIR /workspace

# Set necessary environment variables
ENV DEBIAN_FRONTEND noninteractive\
    SHELL=/bin/bash

# Update, Upgrade and Install Ubuntu packages
RUN apt update && \
    apt -y upgrade && \
    apt install -y  --no-install-recommends \
        software-properties-common \
        git \
        openssh-server \
        libgl1 \
        wget \
        curl \
        apt-transport-https \
        ca-certificates && \
    update-ca-certificates \
    apt clean && \
    rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

# Set Python and pip
RUN ln -s /usr/bin/python3.10 /usr/bin/python && \
    curl https://bootstrap.pypa.io/get-pip.py | python && \
    rm -f get-pip.py

# Create and use the main Python venv
RUN python3 -m venv /workspace/venv

# Install Python packages
RUN source /workspace/venv/bin/activate && \
    pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 && \
    pip install --no-cache-dir xformers jupyterlab ipywidgets jupyter-archive jupyter_contrib_nbextensions && \
    jupyter nbextension enable --py widgetsnbextension

# Move venv to root to support Network volumes
RUN mv /workspace/venv /venv

# Set up the container startup script
COPY start.sh /
RUN chmod a+x /start.sh

# Start the container
CMD [ "/start.sh" ]
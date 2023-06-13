FROM ashleykza/stable-diffusion-models:1.0.0 as sd-models
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04 as runtime

ARG WEBUI_VERSION=v1.3.2
ARG DREAMBOOTH_COMMIT=dc413a14379b165355502d9f65856c40a4bb5b6f
ARG KOHYA_VERSION=v21.7.6
ARG MAIN_VENV=/workspace/venv
ARG KOHYA_VENV=/workspace/kohya_ss/venv

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND noninteractive\
    SHELL=/bin/bash

# Add Stable Diffusion 1.5 model and VAE
RUN mkdir -p /sd-models
COPY --from=sd-models /v1-5-pruned.safetensors /sd-models/v1-5-pruned.safetensors
COPY --from=sd-models /vae-ft-mse-840000-ema-pruned.safetensors /sd-models/vae-ft-mse-840000-ema-pruned.safetensors

# Create workspace working directory
WORKDIR /workspace

# Install Ubuntu packages
RUN apt update && \
    apt -y upgrade && \
    apt install -y --no-install-recommends \
        software-properties-common \
        python3.10-venv \
        python3-tk \
        bash \
        git \
        ncdu \
        net-tools \
        openssh-server \
        libglib2.0-0 \
        libsm6 \
        libgl1 \
        libxrender1 \
        libxext6 \
        ffmpeg \
        wget \
        curl \
        psmisc \
        rsync \
        vim \
        unzip \
        htop \
        pkg-config \
        libcairo2-dev \
        libgoogle-perftools4 libtcmalloc-minimal4 \
        apt-transport-https ca-certificates && \
    update-ca-certificates && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

# Set Python and pip
RUN ln -s /usr/bin/python3.10 /usr/bin/python && \
    curl https://bootstrap.pypa.io/get-pip.py | python && \
    rm -f get-pip.py

# Create and use the main Python venv
RUN python3 -m venv ${MAIN_VENV}

# Install Torch
RUN source ${MAIN_VENV}/bin/activate && \
    pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 && \
    pip install --no-cache-dir xformers && \
    deactivate

# Clone the git repo of the Stable Diffusion Web UI by Automatic1111
# and set version
WORKDIR /workspace
RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git && \
    cd /workspace/stable-diffusion-webui && \
    git reset ${WEBUI_VERSION} --hard

# Complete Jupyter installation
RUN source ${MAIN_VENV}/bin/activate && \
    pip3 install jupyterlab ipywidgets jupyter-archive jupyter_contrib_nbextensions && \
    jupyter contrib nbextension install --user && \
    jupyter nbextension enable --py widgetsnbextension && \
    pip3 install gdown && \
    deactivate

# Install the dependencies for the Automatic1111 Stable Diffusion Web UI
WORKDIR /workspace/stable-diffusion-webui
COPY requirements.txt ./requirements.txt
COPY requirements_versions.txt ./requirements_versions.txt
COPY install.py ./install.py
RUN source ${MAIN_VENV}/bin/activate && \
    python -m install --skip-torch-cuda-test && \
    deactivate

# Clone the Automatic1111 Extensions
RUN git clone https://github.com/d8ahazard/sd_dreambooth_extension.git extensions/sd_dreambooth_extension && \
    git clone https://github.com/deforum-art/sd-webui-deforum extensions/deforum && \
    git clone https://github.com/Mikubill/sd-webui-controlnet.git extensions/sd-webui-controlnet && \
    git clone https://github.com/kohya-ss/sd-webui-additional-networks && \
    git clone https://github.com/KohakuBlueleaf/a1111-sd-webui-locon

# Install depenencies for Deforum and ControlNet
RUN source ${MAIN_VENV}/bin/activate && \
    cd /workspace/stable-diffusion-webui/extensions/deforum && \
    pip3 install -r requirements.txt && \
    cd /workspace/stable-diffusion-webui/extensions/sd-webui-controlnet && \
    pip3 install -r requirements.txt && \
    deactivate

# Set Dreambooth extension version
WORKDIR /workspace/stable-diffusion-webui/extensions/sd_dreambooth_extension
RUN git checkout main && \
    git reset ${DREAMBOOTH_COMMIT} --hard

# Install the dependencies for the Dreambooth extension
COPY requirements_dreambooth.txt ./requirements.txt
RUN source ${MAIN_VENV}/bin/activate && \
    pip3 install -r requirements.txt && \
    deactivate

# Fix Tensorboard
RUN source ${MAIN_VENV}/bin/activate && \
    pip3 uninstall -y tensorboard tb-nightly && \
    pip3 install tensorboard tensorflow && \
    pip3 cache purge && \
    deactivate

# Install Kohya_ss
ENV TZ=Africa/Johannesburg
RUN git clone https://github.com/bmaltais/kohya_ss.git /workspace/kohya_ss
WORKDIR /workspace/kohya_ss
RUN git checkout ${KOHYA_VERSION} && \
    python3 -m venv ${KOHYA_VENV} && \
    source ${KOHYA_VENV}/bin/activate && \
    pip3 install -r requirements.txt && \
    pip3 install . && \
    pip3 cache purge && \
    deactivate

# Install runpodctl
RUN wget https://github.com/runpod/runpodctl/releases/download/v1.10.0/runpodctl-linux-amd -O runpodctl && \
    chmod a+x runpodctl && \
    mv runpodctl /usr/local/bin

# Move Stable Diffusion, Kohya_ss and venv to the root
# so it doesn't conflict with Network Volumes
WORKDIR /workspace
RUN mv /workspace/venv /venv
RUN mv /workspace/kohya_ss /kohya_ss
RUN mv /workspace/stable-diffusion-webui /stable-diffusion-webui

# Copy Stable Diffusion Web UI config files
COPY webui-user.sh /stable-diffusion-webui/
COPY config.json /stable-diffusion-webui/
COPY ui-config.json /stable-diffusion-webui/

# Set up the container startup script
COPY start.sh /start.sh
RUN chmod a+x /start.sh

# Start the container
SHELL ["/bin/bash", "--login", "-c"]
CMD [ "/start.sh" ]
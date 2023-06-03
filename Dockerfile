ARG BUILDER_IMAGE=nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04
ARG RUNTIME_IMAGE=nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

##############################################################
# Builder Stage
##############################################################
FROM ${BUILDER_IMAGE} as builder

ARG VENV_PATH=/workspace/venv
ARG WEB_UI_VERSION=v1.3.1
ARG DREAMBOOTH_VERSION=1f5f355cf0369f160e69922ce0e0194da9007677

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND noninteractive\
    SHELL=/bin/bash

# Don't write .pyc bytecode
ENV PYTHONDONTWRITEBYTECODE=1

# Create workspace working directory
RUN mkdir -p /workspace
WORKDIR /workspace

# Keep apt cache
RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

# Install Ubuntu packages
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt update && \
    apt -y upgrade && \
    apt install -y  --no-install-recommends \
        software-properties-common \
        bash \
        git \
        curl  \
        libglib2.0-0 \
        libsm6 \
        libgl1 \
        libxrender1 \
        libxext6 \
        pkg-config \
        libcairo2-dev \
        apt-transport-https ca-certificates && \
        update-ca-certificates

# Install Python 3.10
RUN add-apt-repository ppa:deadsnakes/ppa && \
    apt update && \
    apt install python3.10-dev python3.10-venv python3-tk -y --no-install-recommends && \
	ln -s /usr/bin/python3.10 /usr/bin/python && \
	rm /usr/bin/python3 && \
	ln -s /usr/bin/python3.10 /usr/bin/python3 && \
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python3 get-pip.py && \
    rm get-pip.py

# Create and use the Python venv
RUN --mount=type=cache,target=/root/.cache/pip \
    python3 -m venv ${VENV_PATH}

# Install core dependencies
ADD core_requirements.txt /workspace
RUN source ${VENV_PATH}/bin/activate && \
    pip3 install --upgrade pip && \
    pip3 install -U -I torch torchvision torchaudio --extra-index-url "https://download.pytorch.org/whl/cu118" && \
    pip3 install wheel xformers && \
    pip3 install -r /workspace/core_requirements.txt

# Clone the git repo of the Stable Diffusion Web UI by Automatic1111
# and set the desired version
WORKDIR /workspace
RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git && \
    cd /workspace/stable-diffusion-webui && \
    git reset ${WEB_UI_VERSION} --hard

# Install the dependencies for the Automatic1111 Stable Diffusion Web UI
WORKDIR /workspace/stable-diffusion-webui
COPY requirements.txt ./requirements.txt
COPY requirements_versions.txt ./requirements_versions.txt
COPY install.py ./install.py
RUN python3 -m install --skip-torch-cuda-test

# Clone the Automatic1111 Extensions
RUN git clone https://github.com/d8ahazard/sd_dreambooth_extension.git extensions/sd_dreambooth_extension && \
    git clone https://github.com/deforum-art/sd-webui-deforum extensions/deforum && \
    git clone https://github.com/Mikubill/sd-webui-controlnet.git extensions/sd-webui-controlnet

# Install depenencies fpr Deforum and Controlnet
RUN cd /workspace/stable-diffusion-webui/extensions/deforum \
    && pip3 install -r requirements.txt \
    && cd /workspace/stable-diffusion-webui/extensions/sd-webui-controlnet \
    && pip3 install -r requirements.txt

# Set Dreambooth extension version to dev branch commit
WORKDIR /workspace/stable-diffusion-webui/extensions/sd_dreambooth_extension
RUN git checkout dev && \
    git reset ${DREAMBOOTH_VERSION} --hard

# Install the dependencies for the Dreambooth extension
COPY requirements_dreambooth.txt ./requirements.txt
RUN pip3 install -r requirements.txt

# Install Kohya_ss
ENV TZ=Europe/London
RUN git clone https://github.com/bmaltais/kohya_ss.git /workspace/kohya_ss
WORKDIR /workspace/kohya_ss
RUN pip3 install -r requirements.txt

# Install Tensorboard (usw the version that Kohya_ss requires to start)g
RUN pip3 uninstall -y tb-nightly tensorboardX tensorboard && \
    pip3 install tensorboard==2.10.1


##############################################################
# Runtime Stage
##############################################################
FROM ${RUNTIME_IMAGE} as runtime

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND noninteractive\
    SHELL=/bin/bash

# Python logs go strait to stdout/stderr w/o buffering
ENV PYTHONUNBUFFERED=1

# Don't write .pyc bytecode
ENV PYTHONDONTWRITEBYTECODE=1

# Install Ubuntu packages
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt update && \
    apt -y upgrade && \
    apt install -y  --no-install-recommends \
        software-properties-common \
        bash \
        git \
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
        update-ca-certificates

# Copy Python dependencies from builder to runtime
COPY --from=builder ${VENV_PATH} ${VENV_PATH}
ENV PATH="/workspace/venv/bin:$PATH"

# Clone the git repo of the Stable Diffusion Web UI by Automatic1111
# and set the desired version
WORKDIR /workspace
RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git && \
    cd /workspace/stable-diffusion-webui && \
    git reset ${WEB_UI_VERSION} --hard

# Clone the Automatic1111 Extensions
RUN git clone https://github.com/d8ahazard/sd_dreambooth_extension.git extensions/sd_dreambooth_extension && \
    git clone https://github.com/deforum-art/sd-webui-deforum extensions/deforum && \
    git clone https://github.com/Mikubill/sd-webui-controlnet.git extensions/sd-webui-controlnet

# Set Dreambooth extension version to dev branch commit
WORKDIR /workspace/stable-diffusion-webui/extensions/sd_dreambooth_extension
RUN git checkout dev && \
    git reset ${DREAMBOOTH_VERSION} --hard

# Install Kohya_ss
ENV TZ=Europe/London
RUN git clone https://github.com/bmaltais/kohya_ss.git /workspace/kohya_ss

# Install runpodctl
RUN wget https://github.com/runpod/runpodctl/releases/download/v1.10.0/runpodctl-linux-amd -O runpodctl && \
    chmod a+x runpodctl && \
    mv runpodctl /usr/local/bin

# Install Jupyter
RUN jupyter contrib nbextension install --user && \
    jupyter nbextension enable --py widgetsnbextension &&

# Clean up
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    pip cache purge && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

# Move the /workspace files to / so they don't conflict with Network Volumes
# The start.sh script will rsync them.
WORKDIR /workspace
RUN mv /workspace/stable-diffusion-webui /stable-diffusion-webui
RUN mv /workspace/kohya_ss /kohya_ss
RUN mv /workspace/venv /venv

# Copy Stable Diffusion Web UI launcher and config files
COPY webui_launcher.py /stable-diffusion-webui/launcher.py
COPY kohya_ss_launcher.py /kohya_ss/launcher.py
RUN chmod +x /stable-diffusion-webui/launcher.py
RUN chmod +x /kohya_ss/launcher.py
COPY webui-user.sh /stable-diffusion-webui/
COPY config.json /stable-diffusion-webui/
COPY ui-config.json /stable-diffusion-webui/

# Add Stable Diffusion v1.5 model
ADD https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned.safetensors /stable-diffusion-webui/models/Stable-diffusion/v1-5-pruned.safetensors

# Add VAE
ADD https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.safetensors /stable-diffusion-webui/models/VAE/vae-ft-mse-840000-ema-pruned.safetensors

# Set up the container startup script
COPY start.sh /start.sh
RUN chmod a+x /start.sh

# Start the container
SHELL ["/bin/bash", "--login", "-c"]
CMD [ "/start.sh" ]
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04 as runtime

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND noninteractive\
    SHELL=/bin/bash

# Create workspace working directory
RUN mkdir -p /workspace
WORKDIR /workspace

# Install Ubuntu packages
RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN apt update && \
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

# Install Python 3.10
RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt install python3.10-dev python3.10-venv -y --no-install-recommends && \
	ln -s /usr/bin/python3.10 /usr/bin/python && \
	rm /usr/bin/python3 && \
	ln -s /usr/bin/python3.10 /usr/bin/python3
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
RUN python3 get-pip.py && rm get-pip.py

# Instell torch
RUN pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# Install Jupyter
RUN pip3 install -U jupyterlab ipywidgets jupyter-archive jupyter_contrib_nbextensions
RUN jupyter contrib nbextension install --user
RUN jupyter nbextension enable --py widgetsnbextension

# Install gdown
RUN pip3 install gdown

# Install runpodctl
RUN wget https://github.com/runpod/runpodctl/releases/download/v1.10.0/runpodctl-linux-amd -O runpodctl && \
    chmod a+x runpodctl && \
    mv runpodctl /usr/local/bin

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

# Install Stable Diffusion Web UI by Automatic1111
WORKDIR /workspace
RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git

WORKDIR /workspace/stable-diffusion-webui
RUN git reset v1.3.0 --hard
RUN python -m venv /workspace/venv
ENV PATH="/workspace/venv/bin:$PATH"

WORKDIR /workspace/stable-diffusion-webui
COPY requirements.txt ./requirements.txt
COPY requirements_versions.txt ./requirements_versions.txt
COPY install.py ./install.py
RUN python -m install --skip-torch-cuda-test
RUN pip3 install torch==1.13.1 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
RUN pip3 install https://huggingface.co/MonsterMMORPG/SECourses/resolve/main/xformers-0.0.19-cp310-cp310-manylinux2014_x86_64.whl

# Install Dreambooth Extension for Automatic1111 Web UI
WORKDIR /workspace/stable-diffusion-webui/extensions
RUN git clone https://github.com/d8ahazard/sd_dreambooth_extension.git

WORKDIR /workspace/stable-diffusion-webui/extensions/sd_dreambooth_extension
RUN git reset 1.0.14 --hard
COPY requirements_dreambooth.txt ./requirements.txt
RUN pip3 install -r requirements.txt

# Add Stable Diffusion 1.5 unpruned model
ADD https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned.safetensors /workspace/stable-diffusion-webui/models/Stable-diffusion/v1-5-pruned.safetensors

# Add VAE
ADD https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.safetensors /workspace/stable-diffusion-webui/models/VAE/vae-ft-mse-840000-ema-pruned.safetensors

# Copy Stable Diffusion Web UI launcher and config files
WORKDIR /workspace/stable-diffusion-webui
COPY launcher.py /workspace/stable-diffusion-webui/
COPY webui-user.sh /workspace/stable-diffusion-webui/
COPY config.json /workspace/stable-diffusion-webui/
COPY ui-config.json /workspace/stable-diffusion-webui/

# Set up the container startup script
WORKDIR /
COPY start.sh /start.sh
RUN chmod a+x /start.sh

# Start the container
SHELL ["/bin/bash", "--login", "-c"]
CMD [ "/start.sh" ]
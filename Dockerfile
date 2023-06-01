FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04 as runtime

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND noninteractive\
    SHELL=/bin/bash

# Create workspace working directory
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
RUN add-apt-repository ppa:deadsnakes/ppa && \
    apt update && \
    apt install python3.10-dev python3.10-venv -y --no-install-recommends && \
	ln -s /usr/bin/python3.10 /usr/bin/python && \
	rm /usr/bin/python3 && \
	ln -s /usr/bin/python3.10 /usr/bin/python3 && \
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python3 get-pip.py && \
    rm get-pip.py

# Install runpodctl
RUN wget https://github.com/runpod/runpodctl/releases/download/v1.10.0/runpodctl-linux-amd -O runpodctl && \
    chmod a+x runpodctl && \
    mv runpodctl /usr/local/bin

# Clean up
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    pip cache purge && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

# Clone the git repo of the Stable Diffusion Web UI by Automatic1111
# and set version to v1.3.0
WORKDIR /workspace
RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git && \
    cd /workspace/stable-diffusion-webui && \
    git reset v1.3.0 --hard

# Create and use the Python venv
RUN python3 -m venv /workspace/venv
ENV PATH="/workspace/venv/bin:$PATH"

# Install Jupyter and gdown
RUN pip3 install -U jupyterlab ipywidgets jupyter-archive jupyter_contrib_nbextensions && \
    jupyter contrib nbextension install --user && \
    jupyter nbextension enable --py widgetsnbextension && \
    pip3 install gdown

# Install torch 2.0.1
RUN pip3 install torch==2.0.1 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 && \
    pip3 install xformers

# Install the dependencies for the Automatic1111 Stable Diffusion Web UI
WORKDIR /workspace/stable-diffusion-webui
COPY requirements.txt ./requirements.txt
COPY requirements_versions.txt ./requirements_versions.txt
COPY install.py ./install.py
RUN python -m install --skip-torch-cuda-test

# Clone the Automatic1111 Extensions
RUN git clone https://github.com/d8ahazard/sd_dreambooth_extension.git extensions/sd_dreambooth_extension && \
    git clone https://github.com/deforum-art/sd-webui-deforum extensions/deforum && \
    git clone https://github.com/Mikubill/sd-webui-controlnet.git extensions/sd-webui-controlnet


# Install depenencies fpr Deforum and Controlnet
RUN cd /workspace/stable-diffusion-webui/extensions/deforum \
    && pip3 install -r requirements.txt \
    && cd /workspace/stable-diffusion-webui/extensions/sd-webui-controlnet \
    && pip3 install -r requirements.txt

# Set Dreambooth extension version to dev branch commit b46817bc73807848e726a3f79ef97e156e853928
WORKDIR /workspace/stable-diffusion-webui/extensions/sd_dreambooth_extension
RUN git checkout dev && \
    git reset b46817bc73807848e726a3f79ef97e156e853928 --hard

# Install the dependencies for the Dreambooth extension
COPY requirements_dreambooth.txt ./requirements.txt
RUN pip3 install -r requirements.txt

WORKDIR /workspace/stable-diffusion-webui
RUN mv /workspace/stable-diffusion-webui /stable-diffusion-webui
RUN mv /workspace/venv /venv

# Copy Stable Diffusion Web UI launcher and config files
COPY launcher.py /stable-diffusion-webui/
RUN chmod +x /stable-diffusion-webui/launcher.py
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
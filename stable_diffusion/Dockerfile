FROM ashleykza/stable-diffusion-models:1.0.0 as sd-models
FROM ashleykza/pytorch:2.0.1-117 as runtime

ARG WEBUI_VERSION=v1.3.1
ARG DREAMBOOTH_VERSION=1.0.14

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND noninteractive\
    SHELL=/bin/bash

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
    git reset ${WEBUI_VERSION} --hard

# Create and use the Python venv
    RUN python3 -m venv /workspace/venv
ENV PATH="/workspace/venv/bin:$PATH"

# Install Jupyter and gdown
RUN pip3 install -U jupyterlab ipywidgets jupyter-archive jupyter_contrib_nbextensions && \
    jupyter contrib nbextension install --user && \
    jupyter nbextension enable --py widgetsnbextension && \
    pip3 install gdown

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

# Set Dreambooth extension version
WORKDIR /workspace/stable-diffusion-webui/extensions/sd_dreambooth_extension
RUN git checkout dev && \
    git reset ${DREAMBOOTH_VERSION} --hard

# Install the dependencies for the Dreambooth extension
COPY requirements_dreambooth.txt ./requirements.txt
RUN pip3 install -r requirements.txt

# Install Kohya_ss
ENV TZ=Africa/Johannesburg
RUN git clone https://github.com/bmaltais/kohya_ss.git /workspace/kohya_ss
COPY requirements_kohya.txt /workspace/kohya_ss/requirements.txt
RUN pip3 install -r requirements.txt

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
COPY start.sh /workspace/start.sh
RUN chmod a+x /workspace/start.sh

# Start the container
SHELL ["/bin/bash", "--login", "-c"]
CMD [ "/workspace/start.sh" ]
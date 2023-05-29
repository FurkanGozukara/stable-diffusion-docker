FROM runpod/stable-diffusion:models-1.0.0 as sd-models
FROM runpod/stable-diffusion-models:2.1 as hf-cache
FROM runpod/pytorch:3.10-2.0.0-117 AS runtime

ENV DEBIAN_FRONTEND noninteractive

RUN apt update && \
apt install -y  --no-install-recommends \
    software-properties-common \
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

WORKDIR /workspace

RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git

WORKDIR /workspace/stable-diffusion-webui

RUN git reset v1.3.0 --hard
RUN python -m venv /workspace/venv
ENV PATH="/workspace/venv/bin:$PATH"

RUN pip3 install -U jupyterlab ipywidgets jupyter-archive gdown
RUN jupyter nbextension enable --py widgetsnbextension

WORKDIR /workspace/stable-diffusion-webui

ADD install.py .
RUN python -m install --skip-torch-cuda-test
RUN pip3 install torch==1.13.1 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu117
RUN pip3 install https://huggingface.co/MonsterMMORPG/SECourses/resolve/main/xformers-0.0.19-cp310-cp310-manylinux2014_x86_64.whl

RUN mkdir -p /root/.cache/huggingface && mkdir -p /sd-models

# TODO: Make own model image with safetensors v1.5 and VAE
COPY --from=hf-cache /root/.cache/huggingface /root/.cache/huggingface
COPY --from=sd-models /SDv1-5.ckpt /sd-models/SDv1-5.ckpt
COPY --from=sd-models /SDv2-768.ckpt /sd-models/SDv2-768.ckpt

WORKDIR /workspace/stable-diffusion-webui

ADD relauncher.py /workspace/stable-diffusion-webui/
ADD webui-user.sh /workspace/stable-diffusion-webui/
ADD start.sh /start.sh
RUN chmod a+x /start.sh

SHELL ["/bin/bash", "--login", "-c"]
CMD [ "/start.sh" ]
FROM runpod/stable-diffusion:web-automatic-8.0.0

ENV DEBIAN_FRONTEND noninteractive

RUN apt update && \
apt install -y  --no-install-recommends \
    unzip \
    htop

WORKDIR /workspace/stable-diffusion-webui

RUN git pull origin master
RUN git reset v1.3.0 --hard
RUN python -m venv /workspace/venv
ENV PATH="/workspace/venv/bin:$PATH"

RUN python -m install --skip-torch-cuda-test
RUN pip3 install torch==1.13.1 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu117
RUN pip3 install https://huggingface.co/MonsterMMORPG/SECourses/resolve/main/xformers-0.0.19-cp310-cp310-manylinux2014_x86_64.whl

WORKDIR /workspace/stable-diffusion-webui/extensions

RUN git clone https://github.com/d8ahazard/sd_dreambooth_extension.git

WORKDIR /workspace/stable-diffusion-webui/extensions/sd_dreambooth_extension
RUN git reset 1.0.14 --hard
RUN pip3 install -r requirements.txt

WORKDIR /workspace/stable-diffusion-webui

ADD launcher.py /workspace/stable-diffusion-webui/
ADD webui-user.sh /workspace/stable-diffusion-webui/
ADD start.sh /start.sh
RUN chmod a+x /start.sh

SHELL ["/bin/bash", "--login", "-c"]
CMD [ "/start.sh" ]
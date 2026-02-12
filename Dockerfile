# 1. 必须保留 devel 镜像，因为编译 OpenFold 需要 NVCC
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

# 2. 基础设置
ENV DEBIAN_FRONTEND=noninteractive
ENV TORCH_CUDA_ARCH_LIST="7.0 7.5 8.0 8.6 8.9 9.0+PTX"
ENV FORCE_CUDA="1"
ENV CUDA_HOME="/usr/local/cuda"

# 3. 最小化系统依赖 (只装必须的)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    wget \
    python3 \
    python3-pip \
    python3-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/bin/python3 /usr/bin/python

# 4. 核心：安装 PyTorch (增加 --no-cache-dir 防止爆内存/磁盘)
# 这一步最容易挂，所以单独放
RUN python3 -m pip install --upgrade pip && \
    pip install --no-cache-dir torch==2.1.2 torchvision==0.16.2 torchaudio==2.1.2 --index-url https://download.pytorch.org/whl/cu118

# 5. 安装脚本所需的轻量级依赖
# biotite/pandas/tqdm 是你的 calc_scrmsd.py 必须的
# einops/omegaconf 是 ESMFold/OpenFold 运行必须的
RUN pip install --no-cache-dir \
    numpy \
    pandas \
    scipy \
    biotite \
    tqdm \
    einops \
    omegaconf \
    ml-collections

# 6. 安装 OpenFold 组件 (最耗时步骤)
# 先装 dllogger
RUN pip install --no-cache-dir "git+https://github.com/NVIDIA/dllogger.git"

# 再装 OpenFold (编译过程约 10-20 分钟)
RUN pip install --no-cache-dir "git+https://github.com/aqlaboratory/openfold.git@4b41059694619831a7db195b7e0988fc4ff3a307"

# 7. 最后安装 ESMFold
RUN pip install --no-cache-dir "fair-esm[esmfold]"

WORKDIR /workspace

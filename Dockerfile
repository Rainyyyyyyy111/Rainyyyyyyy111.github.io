# ==============================================================================
# 1. 基础镜像选择
# 必须使用 'devel' 版本，因为它包含 nvcc 编译器，这是编译 OpenFold 的硬性条件。
# ==============================================================================
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

# ==============================================================================
# 2. 环境变量设置
# ==============================================================================
ENV DEBIAN_FRONTEND=noninteractive
# 显式指定 CUDA 架构，覆盖常见的 HPC 卡 (V100, A100, A40, H100)
ENV TORCH_CUDA_ARCH_LIST="7.0 7.5 8.0 8.6 8.9 9.0+PTX"
ENV FORCE_CUDA="1"
# 确保编译时能找到 CUDA
ENV CUDA_HOME="/usr/local/cuda"

# ==============================================================================
# 3. 系统依赖安装
# git/wget: 下载源码
# build-essential: 编译 C++ 扩展
# ==============================================================================
RUN apt-get update && apt-get install -y \
    git \
    wget \
    python3 \
    python3-pip \
    python3-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# 建立 python 到 python3 的软链接，方便脚本调用
RUN ln -s /usr/bin/python3 /usr/bin/python

# ==============================================================================
# 4. 核心 Python 环境 (PyTorch)
# 安装与 CUDA 11.8 对应的 PyTorch 版本
# ==============================================================================
RUN python3 -m pip install --upgrade pip && \
    pip install torch==2.1.2 torchvision==0.16.2 torchaudio==2.1.2 --index-url https://download.pytorch.org/whl/cu118

# ==============================================================================
# 5. 科学计算与生物信息 "安全网" (防止隐式依赖缺失)
# einops, omegaconf, biopython 是这里的重点
# ==============================================================================
RUN pip install \
    numpy \
    pandas \
    scipy \
    biotite \
    tqdm \
    biopython \
    einops \
    omegaconf \
    ml-collections \
    model-index

# ==============================================================================
# 6. 安装复杂依赖 (DLLogger & OpenFold)
# ==============================================================================
# 6.1 安装 NVIDIA DLLogger (OpenFold 前置)
RUN pip install "git+https://github.com/NVIDIA/dllogger.git"

# 6.2 安装 OpenFold
# 这是一个耗时步骤，GitHub Runner 可能会跑 10-20 分钟
RUN pip install "git+https://github.com/aqlaboratory/openfold.git@4b41059694619831a7db195b7e0988fc4ff3a307"

# ==============================================================================
# 7. 安装 ESMFold
# ==============================================================================
RUN pip install "fair-esm[esmfold]"

# ==============================================================================
# 8. 收尾工作
# ==============================================================================
WORKDIR /workspace
CMD ["python3"]

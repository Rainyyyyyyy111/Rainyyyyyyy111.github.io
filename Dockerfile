# 1. 选择基础镜像：包含 CUDA 11.8 和开发工具 (编译 OpenFold 必须)
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

# 2. 设置环境变量，防止安装过程弹出交互式问答
ENV DEBIAN_FRONTEND=noninteractive
# 设置 CUDA 架构列表，确保兼容 HPC 上的 A100/A40/V100 等显卡
ENV TORCH_CUDA_ARCH_LIST="7.0 7.5 8.0 8.6 8.9 9.0+PTX"
ENV FORCE_CUDA="1"

# 3. 安装系统基础工具
RUN apt-get update && apt-get install -y \
    git \
    wget \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# 4. 升级 pip 并安装 PyTorch (对应 CUDA 11.8)
RUN python3 -m pip install --upgrade pip && \
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# 5. 安装 ODesign 的基础依赖
RUN pip install biotite pandas tqdm "fair-esm[esmfold]"

# 6. 安装 DLLogger (OpenFold 依赖)
RUN pip install "git+https://github.com/NVIDIA/dllogger.git"

# 7. 安装最难啃的 OpenFold
# 注意：这步会进行大量的编译，在 GitHub Action 上可能需要 20-40 分钟
RUN pip install "git+https://github.com/aqlaboratory/openfold.git@4b41059694619831a7db195b7e0988fc4ff3a307"

# 8. 设置默认工作目录
WORKDIR /workspace

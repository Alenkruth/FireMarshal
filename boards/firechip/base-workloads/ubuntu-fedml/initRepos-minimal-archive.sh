#!/bin/bash
set -euo pipefail

# --------------------------
# System update and essentials
# --------------------------
apt-get update -y
apt-get install -y software-properties-common 
apt-get install -y git 
apt-get install -y wget 
apt-get install -y curl 
apt-get install -y build-essential
apt-get install -y cmake 
apt-get install -y ninja-build
# apt-get install python3.10 python3.10-dev
#apt-get install -y python3 
#apt-get install -y python3-dev

#add-apt-repository -y ppa:deadsnakes/ppa
#apt-get update -y

apt-get install -y libncurses5-dev 
apt-get install -y libffi-dev 
apt-get install -y libsqlite3-dev
apt-get install -y libreadline-dev 
apt-get install -y libbz2-dev 
apt-get install -y liblzma-dev
apt-get install -y gfortran
apt-get install -y libssl-dev
apt-get install -y zlib1g-dev
apt-get install -y libcurl4-openssl-dev
apt-get install -y autoconf 
apt-get install -y automake 
apt-get install -y libtool
apt-get install -y libarchive-dev
apt-get install -y libexpat1-dev

# get tar and gzip
# assuming we have it because we were able to install python

wget https://www.python.org/ftp/python/3.10.14/Python-3.10.14.tgz
tar -xf Python-3.10.14.tgz
cd Python-3.10.14

./configure --enable-optimizations
make
make altinstall   # installs as /usr/local/bin/python3.10

echo "Message: Python path is $(which python3)"
# Install Python 3.10 and matching headers
apt-get update
# apt-get install -y python3.10 
# apt-get install -y python3.10-dev 
# apt-get install -y python3.10-distutils 
# apt-get install -y python3.10-venv

# Make python3 point to python3.10 (optional, but often useful)
# update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 2
# update-alternatives --config python3

# Install pip for Python 3.10
curl -sS https://bootstrap.pypa.io/get-pip.py | python3.10

# Reinstall setuptools and pkg-config under the new Python
/usr/local/bin/python3.10 -m pip install --upgrade pip setuptools wheel
apt-get install -y pkg-config


#apt-get install -y python3-pip
#apt-get install -y pkg-config
#apt-get install -y python3.10-setuptools

# Optional: universe repository for extra packages
add-apt-repository universe
apt-get update -y

# Install basic LAPACK/BLAS development headers if available
apt-get install -y liblapack-dev libblas-dev

# --------------------------
# Build OpenBLAS from source
# --------------------------
# Install prerequisites for OpenBLAS

# # Clone OpenBLAS
# cd /opt
# git clone https://github.com/xianyi/OpenBLAS.git
# cd OpenBLAS
# 
# # Checkout a stable release
# git checkout v0.3.23
# 
# # Build OpenBLAS for native RISC-V
# make -j$(nproc)
# make PREFIX=/opt/OpenBLAS install
# 
# # Set environment variables so PyTorch finds OpenBLAS/LAPACK
# export OpenBLAS_HOME=/opt/OpenBLAS
# export CMAKE_PREFIX_PATH=${OpenBLAS_HOME}:${CMAKE_PREFIX_PATH:-}

echo "Message: Python path after installing python3.10 is $(which /usr/local/bin/python3.10)"
export PYTHON_EXECUTABLE=/usr/local/bin/python3.10

# --------------------------
# Python setup
# --------------------------
/usr/local/bin/python3.10 -m pip install --upgrade pip setuptools wheel typing_extensions future six numpy
/usr/local/bin/python3.10 -m pip install --upgrade importlib_metadata
/usr/local/bin/python3.10 -m pip install --upgrade cmake

# --------------------------
# Clone PyTorch
# --------------------------
# cd /opt
# git clone --recursive https://github.com/pytorch/pytorch
# cd pytorch
# 
# # Pin a stable commit/release
# git checkout 9a665ca
# git submodule sync
# git submodule update --init --recursive
# 
# echo "[Patch] Normalizing cmake_minimum_required across all submodules"
# find third_party -type f -name CMakeLists.txt \
#   -exec sed -i -E \
#   's/cmake_minimum_required\(VERSION[[:space:]]+[0-9.]+\)/cmake_minimum_required(VERSION 3.5...3.25)/' {} +

# echo "[MESSAGE] Fixing CMAKELISTS of protobuf"
# sed -i 's/cmake_minimum_required(VERSION 2.8)/cmake_minimum_required(VERSION 3.5...3.25)/' third_party/protobuf/cmake/CMakeLists.txt
# sed -E -i 's/cmake_minimum_required\(VERSION[[:space:]]+[0-9]+\.[0-9]+(\.[0-9]+)?\)/cmake_minimum_required(VERSION 3.5...3.25)/' third_party/protobuf/cmake/CMakeLists.txt

# --------------------------
# PyTorch build flags
# --------------------------
# export USE_CUDA=0
# export USE_ROCM=0
# export USE_MKLDNN=0
# export USE_NNPACK=0
# export USE_QNNPACK=0
# export USE_PYTORCH_QNNPACK=0
# export USE_CUDNN=0
# export USE_FBGEMM=0
# export USE_KINETO=0
# export USE_NCCL=0
# export BUILD_TEST=0        # disable C++ tests
# export BUILD_DOCS=0        # disable docs
# export BUILD_BINARY=0      # disable extra binaries
#export BLAS=Generic
#export USE_SYSTEM_BLAS=ON
#export USE_SYSTEM_LAPACK=ON
#export USE_CPUINFO=OFF

# Ensure modern CMake before PyTorch build
ensure_cmake() {
    REQUIRED=3.25.0
    if command -v cmake >/dev/null 2>&1; then
        INSTALLED=$(cmake --version | head -n1 | awk '{print $3}')
        if [ "$(printf '%s\n' "$REQUIRED" "$INSTALLED" | sort -V | head -n1)" = "$REQUIRED" ]; then
            echo "[CMake Check] Found cmake $INSTALLED (OK)"
            return 0
        else
            echo "[CMake Check] Found cmake $INSTALLED (too old, need >= $REQUIRED)"
        fi
    else
        echo "[CMake Check] No cmake found"
    fi

    # Build modern cmake
    CMAKE_VERSION=3.25.2
    echo "[CMake Install] Bootstrapping cmake $CMAKE_VERSION ..."
    wget -q https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz
    tar -xzf cmake-${CMAKE_VERSION}.tar.gz
    cd cmake-${CMAKE_VERSION}
    ./bootstrap -- -DCMAKE_USE_OPENSSL=ON
    make -j$(nproc)
    sudo make install
    cd ..
    rm -rf cmake-${CMAKE_VERSION} cmake-${CMAKE_VERSION}.tar.gz

    echo "[CMake Install] Installed cmake $(cmake --version | head -n1)"
}

# Call this *before* invoking PyTorch's build
ensure_cmake

# # Force use of the freshly built CMake
# export PATH=/usr/local/bin:$PATH
# export CMAKE_COMMAND=$(which cmake)
# 
# # Double check
# echo "Message: Using cmake at: $(which cmake)"
# cmake --version
# 
# ln -sf $(which cmake) /usr/local/bin/cmake3
# 
# # following https://community.milkv.io/t/guide-building-pytorch-2-9-0a0-on-risc-v-debian-rockos/3637
# 
# # cd /opt/pytorch
# # mkdir build
# # cd build
# 
# # echo "Message: Command - cmake .. \
# #     -DUSE_CUDA=OFF \
# #     -DUSE_ROCM=OFF \
# #     -DUSE_NNPACK=OFF \
# #     -DUSE_QNNPACK=OFF \
# #     -DUSE_PYTORCH_QNNPACK=OFF \
# #     -DUSE_CUDNN=OFF \
# #     -DUSE_FBGEMM=OFF \
# #     -DUSE_KINETO=OFF \
# #     -DUSE_NUMPY=ON \
# #     -DUSE_OPENMP=ON \
# #     -DUSE_SYSTEM_BLAS=ON \
# #     -DUSE_SYSTEM_LAPACK=ON \
# #     -DBUILD_TEST=OFF \
# #     -DBUILD_SHARED_LIBS=ON \
# #     -DCMAKE_POLICY_DEFAULT_CMP0126=NEW \
# #     -DUSE_NCCL=OFF \
# #     -DBUILD_PYTHON=True \
# #     -DCMAKE_VERBOSE_MAKEFILE=ON \
# #     -DCMAKE_RULE_MESSAGES=ON \
# #     -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
# #     -DBUILD_BINARY=OFF \
# #     -DBUILD_TEST=OFF \
# #     -DBUILD_DOCS=OFF \
# #     -DBLAS=Generic \
# #     -DUSE_CPUINFO=OFF \
# #     -DUSE_XNNPACK=OFF \
# #     -DMAX_JOBS=1 \
# #     -DPYTHON_EXECUTABLE=/usr/local/bin/python3.10"
# # 
# # # echo "MESSAGE: Running make after configuring cmake"
# # # make
# # 
# # # echo "MESSAGE: Contents of build after make"
# # # ls
# # 
# # # echo "MESSAGE: Contents of ls lib/"
# # # ls lib/
# # 
# # # echo "Message: Clean CMAKE cache"
# # 
# # # cd /opt/pytorch/build
# # # rm -rf CMakeCache.txt CMakeFiles
# # 
# # export CMAKE_ARGS="-DUSE_CUDA=OFF \
# #     -DUSE_ROCM=OFF \
# #     -DUSE_NNPACK=OFF \
# #     -DUSE_QNNPACK=OFF \
# #     -DUSE_PYTORCH_QNNPACK=OFF \
# #     -DUSE_CUDNN=OFF \
# #     -DUSE_FBGEMM=OFF \
# #     -DUSE_KINETO=OFF \
# #     -DUSE_NUMPY=ON \
# #     -DUSE_OPENMP=ON \
# #     -DUSE_SYSTEM_BLAS=ON \
# #     -DUSE_SYSTEM_LAPACK=ON \
# #     -DBUILD_TEST=OFF \
# #     -DBUILD_SHARED_LIBS=ON \
# #     -DCMAKE_POLICY_DEFAULT_CMP0126=NEW \
# #     -DUSE_NCCL=OFF \
# #     -DUSE_XCCL=OFF \
# #     -DUSE_MKLDNN=OFF \
# #     -DBUILD_PYTHON=True \
# #     -DCMAKE_VERBOSE_MAKEFILE=ON \
# #     -DCMAKE_RULE_MESSAGES=ON \
# #     -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
# #     -DBUILD_BINARY=OFF \
# #     -DBUILD_TEST=OFF \
# #     -DBUILD_DOCS=OFF \
# #     -DBLAS=Generic \
# #     -DUSE_CPUINFO=OFF \
# #     -DUSE_XNNPACK=OFF \
# #     -DMAX_JOBS=1 \
# #     -DPYTHON_EXECUTABLE=/usr/local/bin/python3.10 \
# #     -DPYTHON_INCLUDE_DIR=/usr/local/include/python3.10 \
# #     -DPYTHON_LIBRARY=/usr/local/lib/libpython3.10.so" 

# wgetting the prebuilt wheel for pytorch
# cd /opt/
# wget https://www.cs.virginia.edu/~jht9sy/torch-2.9.0a0+git9a665ca-cp310-cp310-linux_riscv64.whl
# /usr/local/bin/python3.10 -m pip install torch-2.9.0a0+git9a665ca-cp310-cp310-linux_riscv64.whl
# echo "Message: Untaring the file"
# tar -xf pytorch.tar.gz

# echo "Message: Building pytorch Wheel"
# cd /opt/pytorch
# /usr/local/bin/python3.10 -m pip install -r requirements.txt --upgrade
# /usr/local/bin/python3.10 -m pip install -r requirements-build.txt --upgrade
# /usr/local/bin/python3.10 setup.py bdist_wheel --verbose

# --------------------------
# Build PyTorch wheel
# --------------------------

# USE_CUDA=OFF \
# USE_ROCM=OFF \
# USE_NNPACK=OFF \
# USE_QNNPACK=OFF \
# USE_PYTORCH_QNNPACK=OFF \
# USE_CUDNN=OFF \
# USE_FBGEMM=OFF \
# USE_KINETO=OFF \
# USE_NUMPY=ON \
# USE_OPENMP=ON \
# USE_SYSTEM_BLAS=ON \
# USE_SYSTEM_LAPACK=ON \
# BUILD_TEST=OFF \
# BUILD_SHARED_LIBS=ON \
# CMAKE_POLICY_DEFAULT_CMP0126=NEW \
# USE_NCCL=OFF \
# BUILD_PYTHON=True \
# CMAKE_VERBOSE_MAKEFILE=ON \
# CMAKE_RULE_MESSAGES=ON \
# CMAKE_EXPORT_COMPILE_COMMANDS=ON \
# BUILD_BINARY=OFF \
# BUILD_TEST=OFF \
# BUILD_DOCS=OFF \
# BLAS=Generic \
# USE_CPUINFO=OFF \
# USE_XNNPACK=OFF \
# MAX_JOBS=1 \
# python3 setup.py bdist_wheel --verbose

# --------------------------
# Install the built wheel
# --------------------------
# /usr/local/bin/python3.10 -m pip install dist/torch-*.whl --no-cache-dir --no-input

# --------------------------
# Verify installation
# --------------------------
# /usr/local/bin/python3.10 - <<'EOF'
# import torch
# print("✅ PyTorch runtime-only build complete")
# print("Torch version:", torch.__version__)
# print("CUDA available:", torch.cuda.is_available())
# EOF


# clone openblas
cd /opt
git clone https://github.com/openmathlib/openblas.git
cd openblas
git checkout 993fad6aebbce34a97d3f8c34d6d79d35b64cc48
make
make PREFIX=/usr/local install

cd ~
/usr/local/bin/python3.10 -m pip install --upgrade scipy 

# wget https://www.cs.virginia.edu/~jht9sy/test.py
# /usr/local/bin/python3.10 test.py

git clone https://github.com/Alenkruth/fl-platform.git
cd fl-platform

/usr/local/bin/python3.10 numpy-version/main.py --model dnn --epochs 20 --batch 32 --lr 0.01

echo "Done!"
sync
poweroff -f
#!/bin/bash
set -euo pipefail

# Kill unattended-upgrades and its timers so they cannot restart mid-build
systemctl stop unattended-upgrades apt-daily.service apt-daily-upgrade.service 2>/dev/null || true
systemctl disable unattended-upgrades apt-daily.timer apt-daily-upgrade.timer 2>/dev/null || true
systemctl mask unattended-upgrades apt-daily.service apt-daily-upgrade.service apt-daily.timer apt-daily-upgrade.timer 2>/dev/null || true
# Release any stale locks left behind
rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/cache/apt/archives/lock
dpkg --configure -a 2>/dev/null || true

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

./configure --enable-shared
make
make altinstall   # installs as /usr/local/bin/python3.10
ldconfig          # register libpython3.10.so.1.0 with the dynamic linker

echo "Message: Python path is $(which python3)"
# Install Python 3.10 and matching headers
apt-get update

# Install pip for Python 3.10
curl -sS https://bootstrap.pypa.io/get-pip.py | python3.10

# Reinstall setuptools and pkg-config under the new Python
/usr/local/bin/python3.10 -m pip install --upgrade pip setuptools wheel
apt-get install -y pkg-config

# Optional: universe repository for extra packages
add-apt-repository universe
apt-get update -y

# Install basic LAPACK/BLAS development headers if available
apt-get install -y liblapack-dev libblas-dev

echo "Message: Python path after installing python3.10 is $(which /usr/local/bin/python3.10)"
export PYTHON_EXECUTABLE=/usr/local/bin/python3.10

# --------------------------
# Python setup
# --------------------------
/usr/local/bin/python3.10 -m pip install --upgrade pip setuptools wheel typing_extensions future six numpy
/usr/local/bin/python3.10 -m pip install --upgrade importlib_metadata
/usr/local/bin/python3.10 -m pip install --upgrade cmake

# clone openblas
cd /opt
git clone https://github.com/openmathlib/openblas.git
cd openblas
git checkout 993fad6aebbce34a97d3f8c34d6d79d35b64cc48
make -j1
make PREFIX=/usr/local install

cd ~
# scipy not needed for FL workload (numpy-only DNN) and takes 3+ hours to build on RISC-V QEMU
# /usr/local/bin/python3.10 -m pip install --upgrade scipy

# wget https://www.cs.virginia.edu/~jht9sy/test.py
# /usr/local/bin/python3.10 test.py

git clone https://github.com/Alenkruth/fl-platform.git
cd fl-platform

/usr/local/bin/python3.10 numpy_version/main.py --model dnn --epochs 20 --batch 32 --lr 0.01

echo "Done!"
sync
poweroff -f
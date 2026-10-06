#!/bin/bash
#dnf makecache
echo "MESSAGE: Exporting MPLLOCALFREETYPE=0"
export MPLLOCALFREETYPE=0

echo "MESSAGE: Setting dpkg up to use default configuration and running update"
DEBIAN_FRONTEND=noninteractive apt-get \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" \
    update -y

echo "MESSAGE: Setting dpkg up to use default configuration and running upgrade"
DEBIAN_FRONTEND=noninteractive apt-get \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" \
    upgrade -y

echo "MESSAGE: Installing Python3"
apt-get install -y python3
apt-get install -y python3-pip
apt-get install -y python3-tk
apt-get install -y python3-dev python3-setuptools
apt-get install -y python3-matplotlib
apt-get install -y python3-testresources

apt install -y libmpich-dev  
apt install -y libopenmpi-dev
apt install -y openssl
apt install -y libssl-dev
apt-get install -y cmake 
apt-get install -y ninja-build 
apt-get install -y libtiff5-dev 
apt-get install -y libjpeg8-dev 
apt-get install -y libopenjp2-7-dev 
apt-get install -y zlib1g-dev
apt-get install -y libfreetype6-dev 
apt-get install -y liblcms2-dev 
apt-get install -y libwebp-dev 
apt-get install -y tcl8.6-dev
apt-get install -y tk8.6-dev
apt-get install -y libharfbuzz-dev 
apt-get install -y libfribidi-dev 
apt-get install -y libxcb1-dev
apt install -y build-essential 
apt install -y autoconf 
apt install -y automake 
apt install -y libtool 
apt install -y pkg-config
apt install -y libpng-dev 
apt install -y libopenblas-dev

echo "MESSAGE: Pip version is "
python3 -m pip --version

echo "MESSAGE: Setting dpkg up to use default configuration and running upgrade, again"
DEBIAN_FRONTEND=noninteractive apt-get -y \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" \
    upgrade -y

echo "MESSAGE:running dpkg --audit to check if there are any packages unconfigured"
dpkg --audit

echo "MESSAGE: Listing pip packages"
python3 -m pip list

#matplotlib has been commented and will be installed through apt
echo "MESSAGE: Installing pip packages"
for pkg in mpi4py numpy python-gflags pandas mpmath pillow python-dateutil; do
    echo "MESSAGE: Installing $pkg"
    python3 -m pip install --upgrade --force-reinstall --no-input --quiet --disable-pip-version-check --no-cache-dir "$pkg" || echo "Failed to install $pkg, skipping..."
    echo "MESSAGE: Listing pip packages after every new package install"
    python3 -m pip list
done

echo "MESSAGE: Installing Torch"
# python3 -m pip install torch --index-url https://download.pytorch.org/whl/cpu \
#    --no-input -q --disable-pip-version-check --no-cache-dir
pip install torch --disable-pip-version-check --no-cache-dir --prefer-binary --extra-index-url https://ext.kmtea.eu/simple
# pip3 install --no-input --upgrade mpi4py matplotlib numpy python-gflags pandas torch mpmath pillow python-dateutil

echo "MESSAGE: Listing pip packages"
python3 -m pip list

# reboot

echo "MESSAGE: Setting dpkg up to use default configuration and running upgrade, again"
DEBIAN_FRONTEND=noninteractive apt-get -y \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" \
    upgrade -y

sync
poweroff -f
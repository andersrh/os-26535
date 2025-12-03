FROM quay.io/almalinuxorg/atomic-desktop-kde:10
ARG CACHEBUST=1

# Get list of kernels from my repo. If the list has been updated, then the image will be rebuilt. If it hasn't been updated, then caching of the previous build will be used.
ADD "https://copr.fedorainfracloud.org/api_3/build/list?ownername=andersrh&projectname=my-ostree-os&packagename=kernel" /tmp/builds.txt

RUN echo 'omit_drivers+=" nouveau "' | tee /etc/dracut.conf.d/blacklist-nouveau.conf

COPY bin/set_next_version.sh /tmp
RUN /tmp/set_next_version.sh

COPY repo/*.repo /etc/yum.repos.d/
RUN dnf config-manager --add-repo=https://negativo17.org/repos/epel-nvidia.repo -y

# This is necessary for the speakers and internal microphone
RUN dnf install -y alsa-sof-firmware

RUN dnf install --nogpgcheck -y https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-$(rpm -E %rhel).noarch.rpm https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-$(rpm -E %rhel).noarch.rpm

RUN dnf install -y fish distrobox nvtop intel-media-driver libva-intel-driver htop
RUN dnf install -y https://github.com/TheAssassin/AppImageLauncher/releases/download/v2.2.0/appimagelauncher-2.2.0-travis995.0f91801.x86_64.rpm

# Install Negativo17 Nvidia driver
RUN dnf install -y dkms-nvidia nvidia-driver nvidia-persistenced opencl-filesystem libva-nvidia-driver kernel-devel-matched
RUN dkms install nvidia/$(ls /usr/src/ | grep nvidia- | cut -d- -f2-) -k $(rpm -q --queryformat "%{VERSION}-%{RELEASE}.%{ARCH}\n" kernel)

# Remove plocate to avoid updatedb going crazy with scanning the file system once a day
RUN dnf remove -y plocate

# Install libheif-freeworld to show thumbnails in Dolphin
RUN dnf install libheif-freeworld -y

# Install proprietary codecs
RUN dnf swap libavcodec-free libavcodec-freeworld --allowerasing -y

RUN dnf -y install gwenview haruna kalk okular
RUN dnf -y install chromium firefox
# Delete default Chromium config so it can be replaced by my own
RUN rm -f /etc/chromium/chromium.conf

# Add rule to SELinux allowing modules to be loaded into custom kernel
RUN setsebool -P domain_kernel_load_modules on

COPY etc /etc
COPY usr /usr

RUN cd /usr/bin && wget https://raw.githubusercontent.com/CachyOS/CachyOS-Settings/refs/heads/master/usr/bin/kerver && chmod +x kerver

RUN rm -rf /tmp/* /var/* && mkdir -p /var/tmp && chmod -R 1777 /var/tmp && \
bootc container lint

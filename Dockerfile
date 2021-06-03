ARG UBUNTU_VERSION=20.04
ARG CUDA=11.0.3
ARG CUDNN_MAJOR_VERSION=8
ARG TF_PACKAGE_VERSION=2.4.1
FROM nvidia/cuda${ARCH:+-$ARCH}:${CUDA}-cudnn${CUDNN_MAJOR_VERSION}-devel-ubuntu${UBUNTU_VERSION} as base

# ARCH and CUDA are specified again because the FROM directive resets ARGs
# (but their default value is retained if set previously)
ARG ARCH
ARG CUDA

ARG DEBIAN_FRONTEND=noninteractive

# Needed for string substitution
SHELL ["/bin/bash", "-c"]


# --- OpenCV --- (build first to keep it cached)
# Dependencies
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends software-properties-common \
    curl unzip build-essential gcc make cmake pkg-config python3 python3-dev python3-pip\
    libgtk-3-dev ninja-build

# Install dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
  autoconf \
  automake \
  autopoint \
  bison \
  flex \
  libtool \
  yasm \
  nasm \
  git-core \
  build-essential \
  gettext \
  meson \
  libegl1-mesa-dev \
  libgl1-mesa-dev \
  libgles2-mesa-dev \
  libavfilter-dev \
  libavresample-dev \
  libglib2.0-dev \
  libgirepository1.0-dev \
  libpthread-stubs0-dev \
  libssl-dev \
  liborc-dev \
  libmpg123-dev \
  libmp3lame-dev \
  libsoup2.4-dev \
  libshout3-dev \
  libva-dev \
  libxv-dev \
  libcdparanoia-dev \
  libpango1.0-dev \
  libvisual-0.4-dev \
  libvorbisidec-dev \
  libaa1-dev \
  libcaca-dev \
  libdv4-dev \
  libjack-dev \
  libtag1-dev \
  libdrm-dev \
  libvpx-dev \
  libass-dev \
  libzbar-dev \
  libx265-dev \
  libx264-dev \
  libwildmidi-dev \
  libvulkan-dev \
  libx11-dev \
  libxrandr-dev \
  libwayland-dev \
  wayland-protocols \
  libvdpau-dev \
  libsrtp2-dev \
  libvo-aacenc-dev \
  libvo-amrwbenc-dev \
  libbs2b-dev \
  libdc1394-22-dev \
  libdts-dev \
  libfaac-dev \
  libfaad-dev \
  libfdk-aac-dev \
  libfluidsynth-dev \
  libcurl-ocaml-dev \
  libgme-dev \
  libgsm1-dev \
  librtmp-dev \
  libcurl-ocaml-dev \
  libjpeg-turbo8-dev \
  liba52-0.7.4-dev \
  libcdio-dev \
  libtwolame-dev \
  libx264-dev \
  libmpeg2-4-dev \
  libsidplay1-dev \
  gobject-introspection \
  libudev-dev \
  python3-gi \
  python-gi-dev \
  graphviz \
  libnice-dev

ARG GST_VERSION=1.18.3
# Fetch and build GStreamer
RUN git clone -b $GST_VERSION --depth 1 git://anongit.freedesktop.org/git/gstreamer/gstreamer && \
  cd gstreamer && \
  git checkout $GST_VERSION && \
  meson build --buildtype=release --prefix=/usr --libdir=/usr/lib && \
  ninja -C build -j `nproc` && \
  ninja -C build install && \
  cd .. && \
  rm -rvf /gstreamer

# Fetch and build gst-plugins-base
RUN git clone -b $GST_VERSION --depth 1 git://anongit.freedesktop.org/git/gstreamer/gst-plugins-base && \
  cd gst-plugins-base && \
  meson build --buildtype=release --prefix=/usr --libdir=/usr/lib && \
  ninja -C build -j `nproc` && \
  ninja -C build install && \
  cd .. && \
  rm -rvf /gst-plugins-base

# Fetch and build gst-plugins-good
RUN git clone -b $GST_VERSION --depth 1 git://anongit.freedesktop.org/git/gstreamer/gst-plugins-good && \
  cd gst-plugins-good && \
  meson build --buildtype=release --prefix=/usr --libdir=/usr/lib && \
  ninja -C build -j `nproc` && \
  ninja -C build install && \
  cd .. && \
  rm -rvf /gst-plugins-good

# Fetch and build gst-plugins-bad
RUN git clone -b $GST_VERSION --depth 1 git://anongit.freedesktop.org/git/gstreamer/gst-plugins-bad && \
  cd gst-plugins-bad && \
  meson build --buildtype=release --prefix=/usr --libdir=/usr/lib && \
  ninja -C build -j `nproc` && \
  ninja -C build install && \
  cd .. && \
  rm -rvf /gst-plugins-bad

# Fetch and build gst-plugins-ugly
RUN git clone -b $GST_VERSION --depth 1 git://anongit.freedesktop.org/git/gstreamer/gst-plugins-ugly && \
  cd gst-plugins-ugly && \
  meson build --buildtype=release --prefix=/usr --libdir=/usr/lib && \
  ninja -C build -j `nproc` && \
  ninja -C build install && \
  cd .. && \
  rm -rvf /gst-plugins-ugly
  
# Fetch and build gst-libav
RUN git clone -b $GST_VERSION --depth 1 git://anongit.freedesktop.org/git/gstreamer/gst-libav && \
  cd gst-libav && \
  meson build --buildtype=release --prefix=/usr --libdir=/usr/lib && \
  ninja -C build -j `nproc` && \
  ninja -C build install && \
  cd .. && \
  rm -rvf /gst-libav
  
# Fetch and build gst-rtsp-server
# RUN git clone -b $GST_VERSION --depth 1 git://anongit.freedesktop.org/git/gstreamer/gst-rtsp-server && \
#   cd gst-rtsp-server && \
#   meson build --buildtype=release --prefix=/usr --libdir=/usr/lib && \
#   ninja -C build -j `nproc` && \
#   ninja -C build install && \
#   cd .. && \
#   rm -rvf /gst-rtsp-server
  
# Fetch and build gstreamer-vaapi
# RUN git clone -b $GST_VERSION --depth 1 git://anongit.freedesktop.org/git/gstreamer/gstreamer-vaapi && \
#  cd gstreamer-vaapi && \
#  meson build --buildtype=release --prefix=/usr --libdir=/usr/lib && \
#  ninja -C build -j `nproc` && \
#  ninja -C build install && \
#  cd .. && \
#  rm -rvf /gstreamer-vaapi
  
# Fetch and build gst-python
RUN git clone -b $GST_VERSION --depth 1 git://anongit.freedesktop.org/git/gstreamer/gst-python && \
  cd gst-python && \
  meson build --buildtype=release --prefix=/usr --libdir=/usr/lib && \
  ninja -C build -j `nproc` && \
  ninja -C build install && \
  cd .. && \
  rm -rvf /gst-python

# Do some cleanup
RUN DEBIAN_FRONTEND=noninteractive  apt-get clean && \
  apt-get autoremove -y

RUN python3 -m pip --no-cache-dir install --upgrade pip setuptools numpy==1.19.5

# Some TF tools expect a "python" binary
RUN ln -s $(which python3) /usr/local/bin/python

# Clone Repo
WORKDIR /opencv
RUN git clone -b '4.5.2' --depth 1 https://github.com/opencv/opencv
RUN git clone -b '4.5.2' --depth 1 https://github.com/opencv/opencv_contrib
# Build openvc with gstreamer support
WORKDIR build
RUN cmake -D CMAKE_BUILD_TYPE=RELEASE \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    -D INSTALL_PYTHON_EXAMPLES=OFF \
    -D INSTALL_C_EXAMPLES=OFF \
    -D PYTHON_EXECUTABLE=$(which python3) \
    -D CMAKE_INSTALL_PREFIX=$(python3 -c "import sys; print(sys.prefix)") \
    -D PYTHON3_EXECUTABLE=$(which python3) \
    -D PYTHON3_INCLUDE_DIR=$(python3 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
    -D PYTHON3_PACKAGES_PATH=$(python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") \
    -D WITH_GSTREAMER=ON \
    -D WITH_OPENEXR=OFF \
    #-D OPENCV_GENERATE_PKGCONFIG=YES \
    -D BUILD_EXAMPLES=OFF \
    -D BUILD_LIST=core,imgcodecs,imgproc,videoio,python3,dnn,cudev,calib3d \
    -D BUILD_SHARED_LIBS=OFF \
    -D OPENCV_EXTRA_MODULES_PATH=../opencv_contrib/modules \
    -D WITH_CUDA=ON \
    -D WITH_CUDNN=ON \
    -D OPENCV_DNN_CUDA=ON \
    -D ENABLE_FAST_MATH=1 \
    -D CUDA_FAST_MATH=1 \
    -D CUDA_ARCH_BIN=6.1 \
    -D WITH_CUBLAS=1 \
    ../opencv
#RUN make -j$(nproc) && make install && ldconfig && make clean
RUN make -j$(nproc) && make install && make clean
RUN rm -r ../opencv
RUN rm -r ../opencv_contrib

# --- Tensorflow --- (based on https://github.com/tensorflow/tensorflow/blob/master/tensorflow/tools/dockerfiles/dockerfiles/gpu.Dockerfile)
# For CUDA profiling, TensorFlow requires CUPTI.
#ENV LD_LIBRARY_PATH /usr/local/cuda/extras/CUPTI/lib64:/usr/local/cuda/lib64:$LD_LIBRARY_PATH

ENV LD_LIBRARY_PATH /lib:/usr/local/lib:/usr/lib:/usr/local/cuda/extras/CUPTI/lib64:/usr/local/cuda/lib64:$LD_LIBRARY_PATH
RUN export GST_PLUGIN_SYSTEM_PATH=$SNAP/usr/lib/gstreamer-1.0
RUN export GST_PLUGIN_PATH=$SNAP/usr/lib/gstreamer-1.0
RUN export GST_PLUGIN_SCANNER=$SNAP/usr/libexec/gstreamer-1.0/gst-plugin-scanner

ARG TF_PACKAGE=tensorflow
RUN python3 -m pip install --no-cache-dir ${TF_PACKAGE}${TF_PACKAGE_VERSION:+==${TF_PACKAGE_VERSION}}

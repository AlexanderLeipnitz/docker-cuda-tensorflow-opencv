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
    curl unzip git build-essential gcc make cmake pkg-config python3 python3-dev python3-pip \
    libgtk-3-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    libavcodec-dev libavformat-dev libswscale-dev libavresample-dev libx264-dev
RUN python3 -m pip --no-cache-dir install --upgrade pip setuptools numpy==1.19.5

# Some TF tools expect a "python" binary
RUN ln -s $(which python3) /usr/local/bin/python

# Clone Repo
WORKDIR /opencv
RUN git clone -b '4.5.1' --depth 1 https://github.com/opencv/opencv
RUN git clone -b '4.5.1' --depth 1 https://github.com/opencv/opencv_contrib
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
    -D OPENCV_GENERATE_PKGCONFIG=YES \
    -D BUILD_EXAMPLES=OFF \
    -D BUILD_LIST=core,imgcodecs,imgproc,videoio,python3,dnn,cudev \
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
RUN make -j$(nproc) && make install && ldconfig && make clean
RUN rm -r ../opencv
RUN rm -r ../opencv_contrib

# --- Tensorflow --- (based on https://github.com/tensorflow/tensorflow/blob/master/tensorflow/tools/dockerfiles/dockerfiles/gpu.Dockerfile)
# For CUDA profiling, TensorFlow requires CUPTI.
ENV LD_LIBRARY_PATH /usr/local/cuda/extras/CUPTI/lib64:/usr/local/cuda/lib64:$LD_LIBRARY_PATH

ARG TF_PACKAGE=tensorflow
RUN python3 -m pip install --no-cache-dir ${TF_PACKAGE}${TF_PACKAGE_VERSION:+==${TF_PACKAGE_VERSION}}

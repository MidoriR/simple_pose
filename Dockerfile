FROM nvcr.io/nvidia/mxnet:19.10-py3

LABEL maintainer="ErikaAI"

ARG REGION=us-west-2

ENV DEBIAN_FRONTEND=noninteractive

LABEL com.amazonaws.sagemaker.capabilities.accept-bind-to-port=true

RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server \
    libatlas-base-dev \
    libcurl4-openssl-dev \
    libopencv-dev

WORKDIR /

COPY sagemaker-mxnet-container-3.1.2.tar.gz /sagemaker_mxnet_container-3.1.2.tar.gz

RUN pip install --no-cache --upgrade --ignore-installed\
    Cython \
    pandas \
    /sagemaker_mxnet_container-3.1.2.tar.gz && \
    rm /sagemaker_mxnet_container-3.1.2.tar.gz

RUN pip install pycocotools \
    sagemaker 

ENV MXNET_CUDNN_AUTOTUNE_DEFAULT=0

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=UTF-8 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

ENV SAGEMAKER_TRAINING_MODULE sagemaker_mxnet_container.training:main

ENV PATH="/opt/ml/code:${PATH}"

COPY /simple_pose /opt/ml/code

ENV SAGEMAKER_SUBMIT_DIRECTORY /opt/ml/code

ENV SAGEMAKER_PROGRAM train_simple_pose-original.py

CMD ["/bin/bash"]
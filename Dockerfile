FROM nvcr.io/nvidia/mxnet:19.10-py3

LABEL maintainer="ErikaAI"

ARG REGION=us-west-2
ARG MMS_VERSION=1.0.5

ENV DEBIAN_FRONTEND=noninteractive

LABEL com.amazonaws.sagemaker.capabilities.accept-bind-to-port=true

RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server \
    libatlas-base-dev \
    libcurl4-openssl-dev \
    libopencv-dev \
    ca-certificates \
    openjdk-8-jdk-headless \
    nginx

WORKDIR /

COPY sagemaker-mxnet-container-3.1.2.tar.gz /sagemaker_mxnet_container-3.1.2.tar.gz
COPY sagemaker_mxnet_serving_container.tar.gz /sagemaker_mxnet_serving_container.tar.gz

RUN pip install --no-cache --upgrade --ignore-installed\
    Cython \
    pandas \
    flask \
    gevent \
    gunicorn \
    flask \
    /sagemaker_mxnet_container-3.1.2.tar.gz && \
    rm /sagemaker_mxnet_container-3.1.2.tar.gz

RUN pip install --no-cache-dir pycocotools \
    sagemaker \
    mxnet-model-server \
    /sagemaker_mxnet_serving_container.tar.gz && \
    rm /sagemaker_mxnet_serving_container.tar.gz

#ENV MXNET_CUDNN_AUTOTUNE_DEFAULT=0

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=UTF-8 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN useradd -m model-server \
    && mkdir -p /home/model-server/tmp \
    && chown -R model-server /home/model-server

COPY mms-entrypoint.py /usr/local/bin/dockerd-entrypoint.py
COPY config.properties /home/model-server

RUN chmod +x /usr/local/bin/dockerd-entrypoint.py

EXPOSE 8080 8081

ENV SAGEMAKER_TRAINING_MODULE sagemaker_mxnet_container.training:main
ENV SAGEMAKER_SERVING_MODULE sagemaker_mxnet_container.serving:main

ENV TEMP=/home/model-server

ENV PATH="/opt/ml/code:${PATH}"

COPY /simple_pose /opt/ml/code

ENV SAGEMAKER_SUBMIT_DIRECTORY /opt/ml/code

ENV SAGEMAKER_PROGRAM train_simple_pose.py

CMD ["/bin/bash"]

ENTRYPOINT [ "python", "usr/local/bin/dockerd-entrypoint.py" ]
CMD ["mxnet-model-server", "--start", "--mms-config", "/home/model-server/config.properties"]
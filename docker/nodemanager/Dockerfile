FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    openjdk-8-jdk \
    curl \
    wget \
    vim \
    net-tools \
    iputils-ping \
    netcat \
    ssh \
    openssh-server \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash hadoop && \
    mkdir -p /home/hadoop/.ssh && \
    ssh-keygen -t rsa -N "" -f /home/hadoop/.ssh/id_rsa && \
    cat /home/hadoop/.ssh/id_rsa.pub >> /home/hadoop/.ssh/authorized_keys && \
    chmod 600 /home/hadoop/.ssh/authorized_keys && \
    chown -R hadoop:hadoop /home/hadoop/.ssh

ENV HADOOP_VERSION=3.3.6
ENV HADOOP_HOME=/opt/hadoop
ENV PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

RUN wget -q https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz && \
    tar -xzf hadoop-${HADOOP_VERSION}.tar.gz && \
    mv hadoop-${HADOOP_VERSION} $HADOOP_HOME && \
    rm hadoop-${HADOOP_VERSION}.tar.gz && \
    chown -R hadoop:hadoop $HADOOP_HOME

RUN sed -i 's|#!/usr/bin/env bash|#!/bin/bash|g' $HADOOP_HOME/bin/hadoop && \
    sed -i 's|#!/usr/bin/env bash|#!/bin/bash|g' $HADOOP_HOME/sbin/start-dfs.sh && \
    sed -i 's|#!/usr/bin/env bash|#!/bin/bash|g' $HADOOP_HOME/sbin/start-yarn.sh

RUN mkdir -p /var/run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config && \
    echo "UserKnownHostsFile=/dev/null" >> /etc/ssh/ssh_config

EXPOSE 8042

WORKDIR /opt/hadoop

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]

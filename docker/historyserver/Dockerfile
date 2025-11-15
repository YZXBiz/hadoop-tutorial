FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    openjdk-8-jdk \
    curl \
    wget \
    vim \
    net-tools \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/*

ENV HADOOP_VERSION=3.3.6
ENV HADOOP_HOME=/opt/hadoop
ENV PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

RUN wget -q https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz && \
    tar -xzf hadoop-${HADOOP_VERSION}.tar.gz && \
    mv hadoop-${HADOOP_VERSION} $HADOOP_HOME && \
    rm hadoop-${HADOOP_VERSION}.tar.gz && \
    chown -R nobody:nogroup $HADOOP_HOME

EXPOSE 19888

WORKDIR /opt/hadoop

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]

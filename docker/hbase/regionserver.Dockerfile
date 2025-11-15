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
    && rm -rf /var/lib/apt/lists/*

ENV HBASE_VERSION=2.5.3
ENV HADOOP_VERSION=3.3.6
ENV HADOOP_HOME=/opt/hadoop
ENV HBASE_HOME=/opt/hbase
ENV PATH=$HADOOP_HOME/bin:$HBASE_HOME/bin:$PATH
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

# Download Hadoop
RUN wget -q https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz && \
    tar -xzf hadoop-${HADOOP_VERSION}.tar.gz && \
    mv hadoop-${HADOOP_VERSION} $HADOOP_HOME && \
    rm hadoop-${HADOOP_VERSION}.tar.gz

# Download HBase
RUN wget -q https://archive.apache.org/dist/hbase/${HBASE_VERSION}/hbase-${HBASE_VERSION}-bin.tar.gz && \
    tar -xzf hbase-${HBASE_VERSION}-bin.tar.gz && \
    mv hbase-${HBASE_VERSION} $HBASE_HOME && \
    rm hbase-${HBASE_VERSION}-bin.tar.gz

EXPOSE 16030

WORKDIR $HBASE_HOME

COPY regionserver-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]

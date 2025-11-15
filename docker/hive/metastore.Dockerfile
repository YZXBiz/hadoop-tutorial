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
    mysql-client \
    && rm -rf /var/lib/apt/lists/*

ENV HIVE_VERSION=3.1.3
ENV HADOOP_VERSION=3.3.6
ENV HADOOP_HOME=/opt/hadoop
ENV HIVE_HOME=/opt/hive
ENV PATH=$HADOOP_HOME/bin:$HIVE_HOME/bin:$PATH
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

# Download Hadoop
RUN wget -q https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz && \
    tar -xzf hadoop-${HADOOP_VERSION}.tar.gz && \
    mv hadoop-${HADOOP_VERSION} $HADOOP_HOME && \
    rm hadoop-${HADOOP_VERSION}.tar.gz

# Download Hive
RUN wget -q https://archive.apache.org/dist/hive/hive-${HIVE_VERSION}/apache-hive-${HIVE_VERSION}-bin.tar.gz && \
    tar -xzf apache-hive-${HIVE_VERSION}-bin.tar.gz && \
    mv apache-hive-${HIVE_VERSION}-bin $HIVE_HOME && \
    rm apache-hive-${HIVE_VERSION}-bin.tar.gz

# Download MariaDB JDBC driver
RUN mkdir -p $HIVE_HOME/lib && \
    cd $HIVE_HOME/lib && \
    wget -q https://downloads.mariadb.com/Connectors/java/connector-java-3.0.8/mariadb-java-client-3.0.8.jar

EXPOSE 9083

WORKDIR $HIVE_HOME

COPY metastore-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]

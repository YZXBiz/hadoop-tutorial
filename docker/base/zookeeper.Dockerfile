FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    openjdk-8-jdk \
    curl \
    wget \
    netcat \
    && rm -rf /var/lib/apt/lists/*

ENV ZOOKEEPER_VERSION=3.8.1
ENV ZOOKEEPER_HOME=/opt/zookeeper
ENV PATH=$ZOOKEEPER_HOME/bin:$PATH
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

RUN wget -q https://archive.apache.org/dist/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/apache-zookeeper-${ZOOKEEPER_VERSION}-bin.tar.gz && \
    tar -xzf apache-zookeeper-${ZOOKEEPER_VERSION}-bin.tar.gz && \
    mv apache-zookeeper-${ZOOKEEPER_VERSION}-bin $ZOOKEEPER_HOME && \
    rm apache-zookeeper-${ZOOKEEPER_VERSION}-bin.tar.gz && \
    mkdir -p /var/lib/zookeeper

RUN echo "server.1=zookeeper:2888:3888" > $ZOOKEEPER_HOME/conf/zoo.cfg && \
    echo "dataDir=/var/lib/zookeeper" >> $ZOOKEEPER_HOME/conf/zoo.cfg && \
    echo "clientPort=2181" >> $ZOOKEEPER_HOME/conf/zoo.cfg && \
    echo "tickTime=2000" >> $ZOOKEEPER_HOME/conf/zoo.cfg && \
    echo "initLimit=5" >> $ZOOKEEPER_HOME/conf/zoo.cfg && \
    echo "syncLimit=2" >> $ZOOKEEPER_HOME/conf/zoo.cfg

EXPOSE 2181 2888 3888

WORKDIR $ZOOKEEPER_HOME

CMD ["zkServer.sh", "start-foreground"]

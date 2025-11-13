FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    openjdk-11-jdk \
    openssh-server \
    ssh \
    && rm -rf /var/lib/apt/lists/*

RUN ssh-keygen -t rsa -P '' -f /root/.ssh/id_rsa \
    && cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys \
    && chmod 0600 /root/.ssh/authorized_keys

COPY hadoop-3.3.6.tar.gz /opt/
RUN tar -xzf /opt/hadoop-3.3.6.tar.gz -C /opt/ \
    && mv /opt/hadoop-3.3.6 /opt/hadoop \
    && rm /opt/hadoop-3.3.6.tar.gz

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV HADOOP_HOME=/opt/hadoop
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

COPY hadoop-configs/* $HADOOP_HOME/etc/hadoop/

CMD service ssh start && tail -f /dev/null

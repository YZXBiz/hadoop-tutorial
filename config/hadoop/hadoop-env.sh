#!/bin/bash

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Set Hadoop-specific environment variables here.

# The only required environment variable is JAVA_HOME or JAVA_PROGRAM_DIR.
# All other environment variables are optional.  When running a distributed hadoop
# cluster, most of the following variables should be set for each machine in the
# CLASSPATH varies depending on how much of Hadoop is being used.  If using the
# whole thing, it could be something like:

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

# The maximum amount of heap to use (in megabytes).
export HADOOP_HEAPSIZE=${HADOOP_HEAPSIZE:-1000}

# Enable extra debugging signal handlers that receive log data.
export HADOOP_NAMENODE_INIT_HEAPSIZE="-Xms1000m -Xmx1000m"

# Extra Java runtime options.
# By default GC is set to 'UseParallelGC' if the server has more than one processor
# core on Linux or Windows. Nevertheless, explicit GC options can be specified here.
# GC_THREAD_OPTS="-XX:+UnlockDiagnosticVMOptions -XX:ParGCCardsPerStrideChunk=4096 -XX:+UnlockExperimentalVMOptions -XX:G1NewCollectionHeuristicPercent=35 -XX:+DisableExplicitGC -XX:InitiatingHeapOccupancyPercent=10"

# NameNode specific parameters are set here by default are invoked in $HADOOP_CONF_DIR/hadoop-env.sh / $HADOOP_COMMON_HOME/libexec/hadoop-config.sh.
# Java property setting for namenode. eg "-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=9010"

# The following variables are deprecated and remain here momentarily for backward
# compatibility.  New users should use the variables from hadoop-env.sh without "_NEW"
# suffix.

# enable the update of HADOOP_*_USER env variables in hadoop-env.sh before getting called by the
# hadoop shell. if not enable then the caller can either invoke hadoop shell w/ these set or
# modified the global hadoop-env.sh

export HADOOP_SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

# Secure hadoop mode (only relevant if security is enabled)
# HADOOP_SECURE_DN_USER=${HADOOP_SECURE_DN_USER}

# This script additionally exports the following variables
# into the global environment (required for execution)
# export JAVA_HOME           - location of java
# export HADOOP_HOME         - location of hadoop
# export HADOOP_CONF_DIR     - location of hadoop etc dir
# export HADOOP_LOG_DIR      - location of hadoop log dir

# Let me also add some performance-related settings
export HADOOP_OPTS="$HADOOP_OPTS -XX:+UseG1GC -XX:MaxGCPauseMillis=200"

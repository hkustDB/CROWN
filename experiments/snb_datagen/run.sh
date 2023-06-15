#!/bin/bash
export PLATFORM_VERSION=$(sbt -batch -error 'print platformVersion')
export DATAGEN_VERSION=$(sbt -batch -error 'print version')
export LDBC_SNB_DATAGEN_JAR=$(sbt -batch -error 'print assembly / assemblyOutputPath')
# export SPARK_HOME="/path/to/spark-3.2.2-bin-hadoop3.2"
# export PATH="${SPARK_HOME}/bin:${PATH}"
SF=$1
./tools/run.py --parallelism 1 --memory 180g -- --format csv --scale-factor ${SF} --mode raw
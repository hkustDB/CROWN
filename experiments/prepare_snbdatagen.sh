#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

cd ${PARENT_PATH} 
git clone https://github.com/ldbc/ldbc_snb_datagen_spark.git

cd ${PARENT_PATH}/ldbc_snb_datagen_spark
sbt assembly

cp -rf ${SCRIPT_PATH}/snb_datagen/run.sh ${PARENT_PATH}/ldbc_snb_datagen_spark/


#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

cd ${PARENT_PATH} 
git clone https://github.com/dbtoaster/dbtoaster-backend.git
git clone https://github.com/dbtoaster/dbtoaster-a5.git
git clone https://github.com/dbtoaster/dbtoaster-experiments-data.git

# checkout to commit id `3c62c0c1da9fcbeedfc79fe7969faa24184ae293`
cd dbtoaster-backend/
git checkout 3c62c0c1da9fcbeedfc79fe7969faa24184ae293
cd ${PARENT_PATH}

# apply the changes in `dbtoaster_modified` to local `dbtoaster-backend` directory (copy and replace)
cp -rf dbtoaster_modified/** dbtoaster-backend/

# delete the `ddbtoaster/lms/DefaultLMSGen.scala` in local `dbtoaster-backend` directory
rm -f dbtoaster-backend/ddbtoaster/lms/DefaultLMSGen.scala

# add the `src/global/Partitioner.ml` from `dbtoaster_frontend_modified` to local `dbtoaster-a5` directory (copy and replace)
cp -rf dbtoaster_frontend_modified/src/global/Partitioner.ml dbtoaster-a5/src/global/

# Create a file `ddbtoaster/conf/ddbt.properties`
ddbt_properties="${PARENT_PATH}/dbtoaster-backend/ddbtoaster/conf/ddbt.properties"
mkdir -p "${PARENT_PATH}/dbtoaster-backend/ddbtoaster/conf"
rm -f ${ddbt_properties}
touch ${ddbt_properties}
echo "# The base_repo path should be absolute" >> ${ddbt_properties}
echo "ddbt.base_repo = ${PARENT_PATH}/dbtoaster-a5" >> ${ddbt_properties}
echo "ddbt.data_repo = ${PARENT_PATH}/dbtoaster-experiments-data" >> ${ddbt_properties}
echo "ddbt.lms = 1" >> ${ddbt_properties}
echo "ddbt.pardis.outputFolder = pardis/lifter" >> ${ddbt_properties}
echo "ddbt.pardis.inputPackage = ddbt.lib.store" >> ${ddbt_properties}
echo "ddbt.pardis.outputPackage = ddbt.lib.store.deep" >> ${ddbt_properties}
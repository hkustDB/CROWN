# Reproducibility of the experiments
## Getting Started
### Prerequisites
The following commands or tools need to be installed in advance.
* GNU Time, GNU sed, GNU awk, GNU getopt
* hdfs - hadoop 2.7.0
* scala - version 2.12.15
* java - version 1.8.0_321
* dotnet - 5.0.403
* maven - 3.8.4
* sbt - 1.4.3
* OCaml - 5.0.0
* g++-11 - gcc-11.2.0
* psql - postgresql-10.23
* pyenv - pyenv-2.3.18
* pyenv virtualenv - pyenv-virtualenv 1.2.1

### Hareware Requirements
Recommended:
- Processors: 32 threads or above
- Memory: 500 GB or above
- Disk: 5 TB Space, 600 MB read/write speed or above 

### Preparation
#### Attention please!
Please make sure your current working directory is the same directory as this README file, and then execute the following scripts or commands!

#### 1.Prepare graph data
1.1 run snap_graph/create_graph_data.sh
```shell
    bash snap_graph/create_graph_data.sh
```
1.2 check the snap_graph directory, it will exists epinions/bitcoin/berkstan/google.txt

#### 2.Prepare snb data
2.1 To run snb_datagen, you need to create a Python virtual environment and install the dependencies.
```shell
    pyenv install 3.7.13
    pyenv virtualenv 3.7.13 ldbc_datagen_tools
    pyenv local ldbc_datagen_tools
```
2.2 To run snb_datagen, you need to install `spark-3.2.2-bin-hadoop3.2`, like this:
```shell
    # 1. change into any directory which you prefer to install package
    # e.g., cd $HOME
    # 2. download spark-3.2.2-bin-hadoop3.2 (make sure to use this specified version)
    curl -O https://archive.apache.org/dist/spark/spark-3.2.2/spark-3.2.2-bin-hadoop3.2.tgz
    # 3. extract the package  
    tar -zxvf spark-3.2.2-bin-hadoop3.2.tgz
    # 4. set environment variables, you should modify it to your own path.
    export SPARK_HOME="/path/to/spark-3.2.2-bin-hadoop3.2"
    export PATH="${SPARK_HOME}/bin":"${PATH}"
```
2.3 run the following script to git clone `ldbc_snb_datagen_spark` and build exectuable
```shell
    bash prepare_snbdatagen.sh
    # if you have questions during preparing `ldbc_snb_datagen_spark`, you can refer to https://github.com/ldbc/ldbc_snb_datagen_spark
```
2.4 Run snb_datagen
```shell
    cd ../ldbc_snb_datagen_spark/
    # make sure to change directory into ldbc_snb_datagen_spark which git clone in step 2.3
    bash run.sh 3
    # here '3' represents scale factor, it can be set to 0.003, 0.1, 0.3, 1, 3, 10...
```
2.5 Set the configuration items at the head of `CROWN/experiments/snb_datagen/snb_data_convert.sh`, like this:
```shell
    SF="3"
    # SF mean scale factor, as we use 3 in step 2.4, we set SF to "3"; if we use 0.003, we should set it to "0_003", make sure to replace '.' to '_'.
    BASE_PATH="/path/to/CROWN"
    # BASE_PATH is the parent path of ldbc_snb_datagen_spark directory, make sure to use the absolute path. 
    SRC_PATH="${BASE_PATH}/ldbc_snb_datagen_spark/out/graphs/csv/raw/composite-merged-fk"
    TARGET_PATH="${BASE_PATH}/SF_${SF}"
    # TARGET_PATH is the snb data output directory
    
    PG_USERNAME="user"
    PG_PORT="5432"
    psql_cmd="/path/to/postgresql/bin/psql"
    # modify these PostgreSql config as your own 

    PG_DATABASE="snb_sf${SF}"
    # you should create a database in PostgreSql with name "snb_sf${SF}"
```
2.6 Covert snb data
* Attention! Make sure to create a database in `PostgreSql` with name `"snb_sf${SF}"` as mentioned in step 2.5 before you run the following commands.
```shell
    cd snb_datagen/
    # make sure to change directory into CROWN/experiments/snb_datagen
    bash snb_data_convert.sh
```
* If success, the converted data can be found under `${TARGET_PATH}` which you set in step 2.5

#### 3.Prepare dbtoaster
3.1 git clone `dbtoaster-backend`, `dbtoaster-a5`, `dbtoaster-experiments-data` and make some modifications
```shell
    bash prepare_dbtoaster.sh
```
3.2 make dbtoaster-a5
```shell
    cd ../dbtoaster-a5/
    # make sure to change directory into dbtoaster-a5 which git clone in step 3.1
    make
```
3.3 If you have questions during preparing dbtoaster, you can refer to https://github.com/dbtoaster/dbtoaster-backend/blob/master/README.md

#### 4.Configurations
Set the following configuration items to the correct values before running. Make sure to use the absolute path.
* CROWN/experiments/experiment.cfg
```shell
    snb.data.base.path=/path/to/snb_data  
    # snb data path is the '${TARGET_PATH}' which you set in step 2.5
    data.tools.home=/path/to/data-tools
    # e.g., data.tools.home=/path/to/CROWN/experiments/data-tools
    graph.input.path=/path/to/snap_graph
    # graph input path is the snap_graph directory which you can know from step 1.1
    # e.g., graph.input.path=/path/to/CROWN/experiments/snap_graph
    crown.code.home=/path/to/crown
    # crown code home is the crown source code path, which can be found in the parent path of this readme 
    # e.g., crown.code.home=/path/to/CROWN/crown
    dbtoaster.backend.home=/path/to/dbtoaster-backend
    # you can find dbtoaster-backend path from step 3
    # e.g., dbtoaster.backend.home=/path/to/CROWN/dbtoaster-backend
    hdfs.cmd.path=/path/to/hdfs
    # e.g., hdfs.cmd.path=/path/to/hadoop-2.7.0/bin/hdfs
    hdfs.root.path=hdfs:///
    # this is your prefer hdfs path which you want to put data file in
    # e.g., hdfs.root.path=hdfs:///users
```
* create CROWN/experiments/dbtoaster/src/main/resources/core-site.xml and CROWN/experiments/dbtoaster/src/main/resources/hdfs-site.xml
```shell
    mkdir -p dbtoaster/src/main/resources
    cp path/to/hadoop-2.7.0/etc/hadoop/core-site.xml dbtoaster/src/main/resources/
    cp path/to/hadoop-2.7.0/etc/hadoop/hdfs-site.xml dbtoaster/src/main/resources/
    # copy the core-site.xml and hdfs-site.xml to resources/ directory. You should update the core/hdfs-site.xml path in above commands to your own path.
```

#### 5.Run experiments


#### 6.Plotting


### Project Main Structure
```
    ├── run_all.sh            # build and execute all
    ├── plot.sh               # plot figure from result
    ├── prepare_dbtoaster.sh  # build dbtoaster
    ├── prepare_snbdatagen.sh # build snb_data gen
    ├── experiment.cfg        # project config file
    ├── common.sh             # basic functions for scripts
    ├── data  # store data producing and converting scripts
    │     ├── convert-data.sh
    │     └── ${experiment_name} 
    |                └── data.csv # converted data for specific experiment
    ├── data-tools  # source code of data converting tools
    │     └── src
    ├── dbtoaster  # dbtoaster executable project folder
    │     ├── ${experiment_name}  
    │     │     └── query.sql # query files of specific experiment
    │     ├── lib  # lib files from compiled dbtoaster-backend
    │     │     └── dbtoaster-*.jar
    │     └── src
    │           └── main
    │                ├── resources  # config files for HDFS and Spark
    │                │     ├── core-site.xml
    │                │     ├── hdfs-site.xml
    │                │     ├── spark.config.${experiment_name}.perf
    │                └── scala
    │                    └── experiments
    │                        └── dbtoaster
    │                            ├── Executable.scala
    │                            ├── Main.scala  # entry of executable
    │                            └── ${experiment_name}
    │                                  └── query.scala
    ├── dbtoaster_cpp  # similar to dbtoaster
    ├── flink  # similar to dbtoaster
    ├── crown  # similar to dbtoaster
    ├── trill  # similar to dbtoaster
    ├── plot   # plot code for fig7-10 of paper
    └── specs  # experiment task config file for fig7-10 of paper
```

### Troubleshooting
If you have any trouble in running experiments, please check the logs in `log/` or `system/log/`.

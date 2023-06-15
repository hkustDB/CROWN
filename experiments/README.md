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
1. run snap_graph/create_graph_data.sh
    ```shell
        bash snap_graph/create_graph_data.sh
    ```
2. check the snap_graph directory, it will exists epinions/bitcoin/berkstan/google.txt

#### 2.Prepare snb data
1. To run snb_datagen, you need to create a Python virtual environment and install the dependencies.
    ```shell
        pyenv install 3.7.13
        pyenv virtualenv 3.7.13 ldbc_datagen_tools
        pyenv local ldbc_datagen_tools
    ```
2. To run snb_datagen, you need to install spark-3.2.2-bin-hadoop3.2
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
3. git clone `ldbc_snb_datagen_spark` and build exectuable
    ```shell
        bash prepare_snbdatagen.sh
        # if you have questions during preparing `ldbc_snb_datagen_spark`, you can refer to https://github.com/ldbc/ldbc_snb_datagen_spark
    ```
4. Run snb_datagen
    ```shell
        cd ../ldbc_snb_datagen_spark/
        # make sure to change directory into ldbc_snb_datagen_spark which git clone in step 3.
        bash run.sh 1
        # here '1' represents scale factor, it can be set to 0.003, 0.1, 0.3, 1, 3, 10...
    ```
5. Set the configuration items at the head of `CROWN/experiments/snb_datagen/snb_data_convert.sh`
    ```shell
        SF="1"
        # SF mean scale factor, as we use 1 in step 4, we set SF to "1"; if we use 0.003 in step 4, we should set it to "0_003", make sure to replace '.' to '_'.
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
6. Covert snb data
* Attention! Make sure to create a database in PostgreSql with name "snb_sf${SF}" as mentioned in step 5 before you run the following bash command.
    ```shell
        cd snb_datagen/
        # make sure to change directory into CROWN/experiments/snb_datagen
        bash snb_data_convert.sh
    ```
* If success, the converted data can be found under ${TARGET_PATH} which you set in step 5.

#### 3.Prepare dbtoaster
1. git clone `dbtoaster-backend`, `dbtoaster-a5`, `dbtoaster-experiments-data` and make some modifications
    ```shell
        bash prepare_dbtoaster.sh
    ```
2. make dbtoaster-a5
    ```shell
        cd ../dbtoaster-a5/
        # make sure to change directory into dbtoaster-a5 which git clone in step 1. 
        make
    ```
3. If you have questions during preparing dbtoaster, you can refer to https://github.com/dbtoaster/dbtoaster-backend/blob/master/README.md

#### 4.Configurations
Set the following configuration items to the correct values before running. Make sure to use the absolute path.
* CROWN/experiments/experiment.cfg
    ```shell
        snb.data.base.path=/path/to/snb_data  
        # snb input data should lies under snb_data/${system}/${experiment}/
        data.tools.home=/path/to/data-tools
        # e.g., data.tools.home=/path/to/CROWN/experiments/data-tools
        graph.input.path=/path/to/graph
        # e.g., graph.input.path=/path/to/CROWN/experiments/snap_graph
        crown.code.home=/path/to/crown
        # e.g., crown.code.home=/path/to/CROWN/crown
        dbtoaster.backend.home=/path/to/dbtoaster-backend
        # e.g., dbtoaster.backend.home=/path/to/CROWN/dbtoaster-backend
        hdfs.cmd.path=/path/to/hdfs
        # e.g., hdfs.cmd.path=/path/to/hadoop-2.7.0/bin/hdfs
        hdfs.root.path=hdfs:///
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

## Project Structure
```
    ├── build  # build script entry
    ├── execute  # execute script entry
    ├── common.sh  # basic functions for scripts
    ├── data  # store data producing and converting scripts
    │     ├── convert-data.sh
    │     ├── prepare-tools.sh
    │     ├── produce-data.sh
    │     ├── validate-result.sh    
    │     └── tools.cfg
    ├── data-tools  # source code of data producing and converting tools
    │     └── src
    ├── dbtoaster  # dbtoaster executable project folder
    │     ├── ${experiment_name}  # config and query files of specific experiment
    │     │     ├── common.cfg  # filter condition and other common configs
    │     │     ├── func.cfg  # config for func test
    │     │     ├── perf.cfg  # config for perf test
    │     │     └── query.sql
    │     ├── lib  # lib files from compiled dbtoaster-backend
    │     │     └── dbtoaster-*.jar
    │     ├── build.sh  # script to build dbtoaster executable
    │     ├── execute.sh  # script to run dbtoaster executable
    │     ├── experiment.cfg  # basic config for dbtoaster experiments
    │     ├── prepare-data.sh  # convert data to dbtoaster format
    │     ├── prepare-query.sh  # compile sql to scala file by dbtoaster
    │     ├── prepare-system.sh  # compile dbtoaster
    │     └── src
    │           ├── main
    │           │     ├── resources  # config files for HDFS and Spark
    │           │     │     ├── core-site.xml
    │           │     │     ├── hdfs-site.xml
    │           │     │     ├── spark.config.${experiment_name}.func
    │           │     │     ├── spark.config.${experiment_name}.perf
    │           │     └── scala
    │           │         └── experiments
    │           │             └── dbtoaster
    │           │                 ├── Executable.scala
    │           │                 ├── Main.scala  # entry of executable
    │           │                 └── ${experiment_name}
    │           │                       └── query.scala  # generated by prepare-query.sh
    │           └── test
    │               ├── resources  # config files for Func Test
    │               │     └── ${experiment_name}.config.properties
    │               └── scala
    │                   └── experiments
    │                       └── dbtoaster
    │                           └── ${experiment_name}
    │                                 └── FuncTest.scala
    ├── dbtoaster_cpp  # similar to dbtoaster
    ├── flink  # similar to dbtoaster
    ├── crown  # similar to dbtoaster
    └── trill  # similar to dbtoaster
```

## Troubleshooting
If you have any trouble in running these scripts, please check the logs in `log/` or `system/log/`. 
For example, if an error is thrown in running `build -e length3 -s crown`, you can check the log in `crown/log/build.log`.
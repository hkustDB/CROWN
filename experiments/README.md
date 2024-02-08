# Reproducibility of the experiments
## Getting Started
### Prerequisites
Before proceeding, please ensure the successful installation of the necessary commands and tools listed below.
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
* gnuplot - gnuplot 5.4

Additionally, please ensure availability of the following commands: `git`, `curl`, `tar`, `make`, and `bc`

### Hardware Requirements
We recommend the following hardware specifications:
- Processors: 32 threads or above
- Memory: 500 GB or above
- Disk: 5 TB space, with a read/write speed of 600 MB or above

### Preparation
#### Attention, please!
Please ensure your current working directory matches the location of `this README file` before executing the following scripts or commands.

#### 1.Prepare graph data
1.1 Execute the script `create_graph_data.sh` located in the `snap_graph` directory
```shell
    bash snap_graph/create_graph_data.sh
```
1.2 Upon completion, verify the existence of the `epinions.txt`, `bitcoin.txt`, `berkstan.txt`, and `google.txt` within the `snap_graph` directory.

#### 2.Prepare snb data
For execution of SNB Datagen, please follow the steps outlined below:
2.1 Create a Python virtual environment and install the dependencies.
```shell
    pyenv install 3.7.13
    pyenv virtualenv 3.7.13 ldbc_datagen_tools
    pyenv local ldbc_datagen_tools
```
2.2 Install `spark-3.2.2-bin-hadoop3.2`
```shell
    # 1. Navigate to a directory of your choice, e.g., `cd $HOME`.
    # 2. Download Spark 3.2.2  (make sure to use this specified version)
    curl -O https://archive.apache.org/dist/spark/spark-3.2.2/spark-3.2.2-bin-hadoop3.2.tgz
    # 3. Extract the downloaded package
    tar -zxvf spark-3.2.2-bin-hadoop3.2.tgz
    # 4. Set environment variables. Please ensure to modify them according to your file path. It's recommended to add these variables to your `~/.bash_profile`
    export SPARK_HOME="/path/to/spark-3.2.2-bin-hadoop3.2"
    export PATH="${SPARK_HOME}/bin":"${PATH}"
```
2.3 Clone and Build `ldbc_snb_datagen_spark`
If you encounter any issues during this process, please refer to the [official repository](https://github.com/ldbc/ldbc_snb_datagen_spark).
```shell
    bash prepare_snbdatagen.sh
```
2.4 Run snb_datagen
Navigate to the `ldbc_snb_datagen_spark` directory, which was cloned in the previous step, and execute the run script. Replace '1' with your desired scale factor(can be set to 0.003, 0.1, 0.3, 1, 3, 10...).
```shell
    cd ../ldbc_snb_datagen_spark/
    bash run.sh 1
```
2.5 Configuring SNB Data
Before conversion, it's essential to set configuration items at the beginning of `CROWN/experiments/snb_datagen/snb_data_convert.sh`. Modify the following parameters according to your setup:
```shell
    SF="1"
    # SF mean scale factor, as we use 1 in step 2.4, we set SF to "1"; if we use 0.003, we should set it to "0_003", make sure to replace '.' to '_'.
    BASE_PATH="/path/to/CROWN"
    # BASE_PATH is the parent path of ldbc_snb_datagen_spark directory, make sure to use the absolute path. 
    SRC_PATH="${BASE_PATH}/ldbc_snb_datagen_spark/out/graphs/csv/raw/composite-merged-fk"
    TARGET_PATH="${BASE_PATH}/SF_${SF}"
    # TARGET_PATH is the snb data output directory
    
    PG_USERNAME="user"
    PG_PORT="5432"
    psql_cmd="/path/to/postgresql/bin/psql"
    # PostgreSQL database configurations

    PG_DATABASE="snb_sf${SF}"
    # you should create a database in PostgreSql with the name "snb_sf${SF}" manually
```
2.6 Convert SNB Data
Ensure you have created a database in PostgreSQL with the name "snb_sf${SF}" before proceeding. Execute the following commands.
```shell
    cd snb_datagen/
    bash snb_data_convert.sh
```
Upon successful execution, the converted data will be located under `${TARGET_PATH}` as specified in step 2.5.

#### 3.Prepare DBToaster
To effectively set up DBToaster, please follow these steps:
3.1 Clone and Modify DBToaster Repositories
Execute the provided script `prepare_dbtoaster.sh` to clone the necessary repositories and make the required modifications:
```shell
    bash prepare_dbtoaster.sh
```
3.2 make dbtoaster-a5
Navigate to the `dbtoaster-a5` directory, which was cloned in the previous step, and build DBToaster-A5 by executing the following command
```shell
    cd ../dbtoaster-a5/
    make
```
For any queries during the preparation of DBToaster, please refer to the [official documentation](https://github.com/dbtoaster/dbtoaster-backend/blob/master/README.md).

#### 4.Configurations
Before proceeding, ensure that the following configuration items are set correctly. Please use absolute path.
* Edit CROWN/experiments/experiment.cfg
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
* Copy core-site.xml and hdfs-site.xml
```shell
    mkdir -p dbtoaster/src/main/resources
    cp path/to/hadoop-2.7.0/etc/hadoop/core-site.xml dbtoaster/src/main/resources/
    cp path/to/hadoop-2.7.0/etc/hadoop/hdfs-site.xml dbtoaster/src/main/resources/
    # copy the core-site.xml and hdfs-site.xml to resources/ directory. You should update the core/hdfs-site.xml path in the above commands to your own path.
```

#### 5.Run experiments
#### Quick result
The experiments typically require several days to complete. You have the option to configure the value of `common.experiment.timeout` in the `experiment.cfg` file, which sets the maximum timeout for each task. We recommend using the default configuration of 14400s. Reducing `common.experiment.timeout` can expedite the experiment duration, but it may lead to incomplete result for certain time-consuming tasks in the resulting figures.

#### Spec files
Under the folder `experiments/specs/`, you'll find several `*.spec` files corresponding to experiments detailed in the paper. For instance:
- `parallelism.spec` corresponds to the parallel experiment in Figure 8.
- `enclosureness.spec` corresponds to Figure 7.

Each `*.spec` file comprises several tasks, with each task representing a data point or histogram bar in the figure. For example:
- `task1` in `full_join_queries.spec` measures CROWN's execution time under the 3-Hop (length3_filter) experiment.
- `task3` in `parallelism.spec` measures CROWN's execution time under the experiment of 4-Hop (length4_filter) with a parallelism configuration of 4.

Note: You `DO NOT` need to modify the spec files. 

#### Execute script
Utilize the `experiments/run_all.sh` script to execute all experiments:
```shell
    # This script will run all the experiments for Figure 7-10. 
    bash run_all.sh
    
    # Alternatively, you can run experiments for Figures 7-10 separately:
    # bash build_all.sh - Run this script first to build an executable environment.
    # Then, you can use:
    # - run_fig7.sh to run experiments for Figure 7
    # - run_fig8.sh to run experiments for Figure 8
    # - run_fig9.sh to run experiments for Figure 9
    # - execute_all.sh to run experiments for Figure 10
```

#### Result
Each `*.spec` file contains a `spec.query.name` configuration. All execution results are stored at `experiments/log/result/{spec.query.name}/{task_name}.txt`. For example, the result of `task3` in `parallelism.spec` will be stored at `experiments/log/result/parallelism/task3.txt`. In cases of failed or timed-out executions, the script will write '-1' in the result file.

#### 6.Plotting
You can utilize the `experiments/plot.sh` script to generate all figures at once.
```shell
    # This script will plot the experiment results (Figure 7-10).
    # For Fig 7, the output path is experiments/log/figure/figure7.png
    # For Fig 8, the output path is experiments/log/figure/figure8.png
    # For Fig 9, the output path is experiments/log/figure/figure9.png
    # For Fig 10, the output path is experiments/log/figure/figure10.png
    bash plot.sh
```

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
If you encounter any difficulties while running experiments, please refer to the logs in `log/` or `system/log/`.

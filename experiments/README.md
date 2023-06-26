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
* gnuplot - gnuplot 5.4

Please also make sure the following commands are available: `git`, `curl`, `tar`, `make`, `bc`

### Hardware Requirements
Recommended:
- Processors: 32 threads or above
- Memory: 500 GB or above
- Disk: 5 TB Space, 600 MB read/write speed or above 

### Preparation
#### Attention, please!
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
    # 1. change into any directory in which you prefer to install the package
    # e.g., cd $HOME
    # 2. download spark-3.2.2-bin-hadoop3.2 (make sure to use this specified version)
    curl -O https://archive.apache.org/dist/spark/spark-3.2.2/spark-3.2.2-bin-hadoop3.2.tgz
    # 3. extract the package  
    tar -zxvf spark-3.2.2-bin-hadoop3.2.tgz
    # 4. set environment variables, you should modify them to your own path. You better add it to your ~/.bash_profile.
    export SPARK_HOME="/path/to/spark-3.2.2-bin-hadoop3.2"
    export PATH="${SPARK_HOME}/bin":"${PATH}"
```
2.3 run the following script to git clone `ldbc_snb_datagen_spark` and build executable
```shell
    bash prepare_snbdatagen.sh
    # if you have questions during preparing `ldbc_snb_datagen_spark`, you can refer to https://github.com/ldbc/ldbc_snb_datagen_spark
```
2.4 Run snb_datagen
```shell
    cd ../ldbc_snb_datagen_spark/
    # make sure to change the directory into ldbc_snb_datagen_spark which git clone in step 2.3
    bash run.sh 1
    # here '1' represents scale factor, it can be set to 0.003, 0.1, 0.3, 1, 3, 10...
```
2.5 Set the configuration items at the head of `CROWN/experiments/snb_datagen/snb_data_convert.sh`, like this:
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
    # modify these PostgreSql configs as your own 

    PG_DATABASE="snb_sf${SF}"
    # you should create a database in PostgreSql with the name "snb_sf${SF}"
```
2.6 Covert snb data
* Attention! Make sure to create a database in `PostgreSql` with the name `"snb_sf${SF}"` as mentioned in step 2.5 before you run the following commands.
```shell
    cd snb_datagen/
    # make sure to change the directory into CROWN/experiments/snb_datagen
    bash snb_data_convert.sh
```
* If successful, the converted data can be found under `${TARGET_PATH}` which you set in step 2.5

#### 3.Prepare dbtoaster
3.1 git clone `dbtoaster-backend`, `dbtoaster-a5`, `dbtoaster-experiments-data` and make some modifications
```shell
    bash prepare_dbtoaster.sh
```
3.2 make dbtoaster-a5
```shell
    cd ../dbtoaster-a5/
    # make sure to change the directory into dbtoaster-a5 which git clone in step 3.1
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
    # copy the core-site.xml and hdfs-site.xml to resources/ directory. You should update the core/hdfs-site.xml path in the above commands to your own path.
```

#### 5.Run experiments
#### Quick result
Typically, the experiments take several days to run. You can configure the value of `common.experiment.timeout` in the `experiment.cfg`, which is used to control the maximum timeout for each task. We strongly recommend that you use the default configuration which is 14400s,  Reducing `common.experiment.timeout` can drastically reduce the time needed to run all experiments, but it may also cause the lack of data for some time-consuming tasks in the resulting figure.

#### Spec files
There are some `*.spec` files under the folder `experiments/specs/`. They correspond to the experiments in the paper. For example, the `experiments/specs/parallelism.spec` corresponds to the parallel experiment of Figure 8 in the paper, the `experiments/specs/enclosureness.spec` corresponds to the Figure 7 in the paper, and the other three spec files correspond to the Figure 10 in the paper. Each spec file is composed of several tasks, and each task corresponds to a data point or histogram bar in the figure. For example, the `task1` in the `full_join_queries.spec` measures the execution time of CROWN under the `3-Hop (length3_filter)` experiment; the `task3` in the `parallelism.spec` measures the execution time of CROWN in the experiment of `4-Hop (length4_filter)` under configuration `parallelism = 4`.

#### Execute script
Use the `experiments/run_all.sh` script to execute all experiments.
```shell
    # This script will run all the experiments for Figure 7-10. 
    bash run_all.sh
    
    # If you want to run Figure 7-10 experiments separately, you can do like this:
    # bash build_all.sh, you should run this script first to build an executable environment
    # then you can use run_fig7.sh to run fig7 experiments
    # or use run_fig8.sh to run fig8 experiments
    # or use run_fig9.sh to run fig8 experiments
    # or use execute_all.sh to run fig10 experiments
```

#### Result
Each spec file has a `spec.query.name` configuration. All the execution results are stored at the path `experiments/log/result/{spec.query.name}/{task_name}.txt`. The result of the aforementioned `task3` in `parallelism.spec` will be stored at `experiments/log/result/parallelism/task3.txt`. The script will write a '-1' in the result file for those failed or timed-out executions.

#### 6.Plotting
You can use the `experiments/plot.sh` script to plot all the figures at once.
```shell
    # This script will plot the experiment results(Figure 7-10).
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
If you have any trouble in running experiments, please check the logs in `log/` or `system/log/`.

# Data Experiments
## Getting Started
### Prerequisites
The following commands or tools need to be installed in advance.
* GNU Time, GNU sed, GNU awk, GNU getopt
* hdfs - hadoop 2.7.0
* scala - version 2.11.12
* java - version 1.8.0_60
* dotnet - 5.0.403
* maven - 3.8.4
* sbt - 1.4.3

### Config dbtoaster
1. clone dbtoaster and checkout to commit id 3c62c0c1da9fcbeedfc79fe7969faa24184ae293
2. apply the changes in `dbtoaster_modified` to your local dbtoaster directory(copy and replace)
3. delete the `ddbtoaster/lms/DefaultLMSGen.scala` in your local dbtoaster directory
4. config dbtoaster as described in https://github.com/dbtoaster/dbtoaster-backend/blob/master/README.md
5. add partition info to `src/global/Partitioner.ml` from `dbtoaster_frontend_modified` to your local dbtoaster-a5 directory (copy and replace)
6. `make` your local dbtoaster-a5

### Configurations
Set the following configuration items to the correct values before running.
* data/tools.cfg
    ```shell
        data.tools.home=/path/to/data-tools
        # e.g., data.tools.home=/home/data/lab/this-repo/experiments/data-tools
        graph.input.path=/path/to/graph/file
        # e.g., graph.input.path=/home/data/lab/graph/soc-bitcoin.raw
    ```
* crown/experiment.cfg
    ```shell
        crown.code.home=/path/to/CROWN
        # e.g., crown.code.home=/home/data/lab/this-repo/crown
        crown.experiment.mode=minicluster  # minicluster or test
    ```  
* dbtoaster/experiment.cfg
    ```shell
        dbtoaster.backend.home=/path/to/dbtoaster-backend
        # e.g., dbtoaster.backend.home=/home/data/lab/dbtoaster
        hdfs.cmd.path=/path/to/hdfs
        # e.g., hdfs.cmd.path=/home/data/continuous/hadoop-2.7.0/bin/hdfs
        hdfs.root.path=hdfs:///path/to/experiment/root
        # e.g., hdfs.root.path=hdfs:///users/lab
    ```
* dbtoaster/src/main/resources/core-site.xml and dbtoaster/src/main/resources/hdfs-site.xml
    ```shell
        mkdir -p dbtoaster/src/main/resources
        # copy the core-site.xml and hdfs-site.xml to these two paths
    ```
* dbtoaster_cpp/experiment.cfg
    ```shell
        dbtoaster.backend.home=/path/to/dbtoaster-backend 
        # e.g., dbtoaster.backend.home=/home/data/lab/dbtoaster
    ```
* flink/experiment.cfg
    ```shell
        flink.func.parallelism=xxx
        flink.perf.parallelism=xxx
    ```
* trill/experiment.cfg
    ```shell
        periodic.punctuation.policy.time=xxx
    ```
* experiment.cfg
    ```shell
        snb.data.base.path=/path/to/snb_data  # snb input data should lies under snb_data/${system}/${experiment}/
    ```
* trill inputSize
    ```shell
        # modify the inputSize in length3*/Query.cs, length4*/Query.cs, and star_cnt/Query.cs 
    ```

### Build dbtoaster libs and data-tools
```shell
# build dbtoaster and copy the libs
./build -p dbtoaster
# build the data-tools used in this project
./build -t
```
### Input Data Format
1. graph experiments(length* & star_snt)
```
    # the raw data file should have the following format
    # two digital fields per row, seperated by ','
    # all the edges should be distinct in the entire graph
    src1,dst1
    src2,dst2
    ...
```
2. snb experiments
```
    # the snb input data should lies under {snb.data.base.path}/{system}/{experiment}
    # For example, /path/to/base/trill/snb1_window/
    
    (1) For CROWN, the input data should be in the following format:
    # +/- indicates insertion or deletion
    # the 2nd field indicates the relation name, KN=knows, ME=message, TA=tag, MT=message_tag, PE=person, ...
    # all the input data should be assembly into a single data.csv
    +|KN|f|2853|3850
    +|ME|f|200053|photo200053.jpg|27.112.123.203|Firefox|\N|\N|0|4941|0|5046|\N|\N
    ...
    
    (2) For Trill, the input data should be in the following format:
    # fields seperated by '|'
    # files should be named as trill.{relation}.{window/arbitrary}.csv
    For example, trill.knows.window.csv may looks like:
    1263123695|1263173860|false|2853|3850
    1263123695|1263173860|false|3850|2853
    1263128695|1263173860|false|4899|2853
    ...
    
    (3) For dbtoaster(cpp/spark), the input data should be in the following format:
    # fields seperated by '|'
    # field1 is the timestamp
    # field2 is 1(for insertion) or 0(for deletion)
    # For cpp mode, field2 can be -1(for full enum)
    # For spark mode, need an extra file with name enum-points-perf.txt to indicate the enum points
    # files should be named as {dbtoaster/dbtoaster_cpp}.{relation}.{window/arbitrary}.csv
    For example, dbtoaster.person.window.csv may looks like:
    1262313861|1|f|4941|K.|Kumar|female|1981-05-20|27.112.123.203|Firefox|184|as;mr;en|K.4941@gmail.com
    1262367218|1|f|5723|Rajiv|Singh|male|1983-04-27|27.0.61.254|Firefox|231|mr;ta;en|Rajiv5723@dr-dre.com;Rajiv5723@gmail.com;Rajiv5723@gmail.com
    ...
    
    enum-points-perf.txt may looks like:
    3,18,50,112,209,340,514,763,1072,1527,2142,3109,4257,4935
    # trigger full enum after 3,18,... batches have been processed
    
    (4) For Flink, the input data should be in the following format:
    # fields seperated by '|'
    # files should be named as flink.{relation}.{window/arbitrary}.csv
    # field1 is the timestamp, in format yyyy-MM-dd hh:mm:ss.SSS
    For example, flink.messagetag.window.csv may looks like:
    2010-01-01 10:44:31.102|5036|2961
    2010-01-01 10:44:31.102|5036|0
    2010-01-02 01:33:47.909|6005|7522
    ...
```
## Usage
There are two entries, `build` and `execute`. `build` is used to compile dependencies, prepare data, compile queries, build executables, and perform functional tests. `execute` runs the build product and statistics the time consumption of each system and experiment.
* build 
    ```
        Usage: build [Options]
        
        Options:
          -h, --help		                    print this message.
          -a, --all				            build all dependencies for experiments. (DEFAULT OPTION)
          -t, --data-tools			            build data-tools.
          -p, --prepare-system <sys1,sys2,...>	    prepare systems.
          -s, --system <sys1,sys2,...>	            build excutable for systems.
          -e, --experiment <exp1,exp2,...> 	            produce data and compile queries for experimeents.
        
        Examples:
        (1) build
          Equals to 'build -a' or 'build -t -p all -s all -e all'. Build all dependencies for experiments.
        
        (2) build -t -p dbtoaster
          Build data-tools, then compile and assembly dbtoaster.
        
        (3) build -s dbtoaster,flink
          Build exectuables for system dbtoaster and flink.
        
        (4) build -s flink -e length3 
          Prepare data and compile query of experiment 'length3', then build executable for system flink.
    ```
* execute
    ```
        Usage: execute [Options]
        
        Options:
          -h, --help				print this message.
          -a, --all				        run all experiments in all systems. (DEFAULT OPTION)
          -s, --system <sys1,sys2,...>		run experiments in specific systems only.
          -e, --experiment <exp1,exp2,...> 	        run the specific experiments only.
          -r, --result <file>			output the result into file.
        
        Examples:
        (1) execute
          Equals to 'execute -a' or 'execute -s all -e all'. Run all experiments in all systems.
        
        (2) execute -e length3
          Run experiment 'length3' in all systems.
        
        (3) execute -s dbtoaster,flink
          Equals to 'execute -s dbtoaster,flink -e all'. Run all experiments in system dbtoaster and flink.
        
        (4) execute -s flink -e length3 -r run.log &
          Run experiment 'length3' in system flink and output the result into run.log
    ```
* set filter condition
    ```shell
        bash set-filter-value.sh xxx
        # or modify ${system}/${experiment}/common.cfg directly
    ```
## Supported Systems
* CROWN
* Dbtoaster(Spark)
* Dbtoaster(Cpp)
* Flink(window)
* Trill

## Supported Experiments
* length3_filter 
* length3_project 
* length4_filter 
* length4_project 
* star_cnt 
* snb1_window 
* snb1_arbitrary 
* snb2_window 
* snb2_arbitrary 
* snb3_window 
* snb3_arbitrary 
* snb4_window 
* snb4_arbitrary 
* dumbbell

## Execute the first experiment
```shell
    # prepare data and build executables for all systems with experiment 'length3_filter'
    ./build -e length3_filter -s all
    # execute experiment 'length3_filter' for all systems
    ./execute -e length3_filter -s all
    # if the configuration is done correctly, the script should print something like:
    Experiment: length3_filter
      - dbtoaster:
          Execution time: 134.06 sec
          Configurations:
            batch size = 100
      - dbtoaster_cpp:
          Execution time: 9.33 sec
      - flink:
          Execution time: 12.00 sec
          Configurations:
            parallelism = 1
      - trill:
          Execution time: 23.68 sec
          Configurations:
            punctuation time = 1
      - crown:
          Execution time: 2.76 sec
          Configurations:
            mode = minicluster
            class = L3DistributedJob
            parallelism = 1
```

## Project Structure
```
    ????????? build  # build script entry
    ????????? execute  # execute script entry
    ????????? common.sh  # basic functions for scripts
    ????????? data  # store data producing and converting scripts
    ???     ????????? convert-data.sh
    ???     ????????? prepare-tools.sh
    ???     ????????? produce-data.sh
    ???     ????????? validate-result.sh    
    ???     ????????? tools.cfg
    ????????? data-tools  # source code of data producing and converting tools
    ???     ????????? src
    ????????? dbtoaster  # dbtoaster executable project folder
    ???     ????????? ${experiment_name}  # config and query files of specific experiment
    ???     ???     ????????? common.cfg  # filter condition and other common configs
    ???     ???     ????????? func.cfg  # config for func test
    ???     ???     ????????? perf.cfg  # config for perf test
    ???     ???     ????????? query.sql
    ???     ????????? lib  # lib files from compiled dbtoaster-backend
    ???     ???     ????????? dbtoaster-*.jar
    ???     ????????? build.sh  # script to build dbtoaster executable
    ???     ????????? execute.sh  # script to run dbtoaster executable
    ???     ????????? experiment.cfg  # basic config for dbtoaster experiments
    ???     ????????? prepare-data.sh  # convert data to dbtoaster format
    ???     ????????? prepare-query.sh  # compile sql to scala file by dbtoaster
    ???     ????????? prepare-system.sh  # compile dbtoaster
    ???     ????????? src
    ???           ????????? main
    ???           ???     ????????? resources  # config files for HDFS and Spark
    ???           ???     ???     ????????? core-site.xml
    ???           ???     ???     ????????? hdfs-site.xml
    ???           ???     ???     ????????? spark.config.${experiment_name}.func
    ???           ???     ???     ????????? spark.config.${experiment_name}.perf
    ???           ???     ????????? scala
    ???           ???         ????????? experiments
    ???           ???             ????????? dbtoaster
    ???           ???                 ????????? Executable.scala
    ???           ???                 ????????? Main.scala  # entry of executable
    ???           ???                 ????????? ${experiment_name}
    ???           ???                       ????????? query.scala  # generated by prepare-query.sh
    ???           ????????? test
    ???               ????????? resources  # config files for Func Test
    ???               ???     ????????? ${experiment_name}.config.properties
    ???               ????????? scala
    ???                   ????????? experiments
    ???                       ????????? dbtoaster
    ???                           ????????? ${experiment_name}
    ???                                 ????????? FuncTest.scala
    ????????? dbtoaster_cpp  # similar to dbtoaster
    ????????? flink  # similar to dbtoaster
    ????????? crown  # similar to dbtoaster
    ????????? trill  # similar to dbtoaster
```
## Special Experiments
* length3_filter2
  - length3 experiment with different update sequence. R1,R3 window size is controlled by ${length3.filter2.window.factor1}, R2 window size is controlled by ${length3.filter2.window.factor2}. 
  - trigger full enum for 10 time(only works in dbtoaster and crown full mode) by default.
* length3_filter3(CROWN only)
  - length3 experiment with different update sequence. R2 window size is controlled by ${length3.filter2.window.factor2}. 20 insertion/deletion of R1 and R3 will be performed for each update to R2. 
  - No full enum will be triggered.
* some experiments in trill(ends with '_filter')
  - you have to manually set the input size of the file in `trill/{experiment}/Query.cs` in order to compute the window size correctly.
## Extension
* adding new experiments
  1. create new folders with the name {experiment} under all systems.
  2. add query file and config files(if needed) to the created folders.
  3. add a Scala Object in data-tools to produce data for this experiment.
  4. add the experiment name to valid_experiment_names in common.sh
* adding new systems
  1. add a folder with the system's name under the root path of this project.
  2. create structure like other systems.
  3. create build.sh, execute.sh, prepare-data.sh, prepare-query.sh, prepare-system.sh and implement them.
  4. add the system name to valid_system_names in common.sh
## Troubleshooting
If you have any trouble in running these scripts, please check the logs in `log/` or `system/log/`. 
For example, if an error is thrown in running `build -e length3 -s crown`, you can check the log in `crown/log/build.log`.
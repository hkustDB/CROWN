# ACQ

This is an implementation of our paper Change Propagation Without Joins..

## Prerequisites

### Dependencies
- Java 1.8.0_60
- Scala 2.12.12
- Maven 3.8.4
- Flink 1.13(Optional, if you want to submit to a Flink cluster )

## Project Structure
- `src/main/scala/BasedProcessFunctions` base class for process functions
- `src/main/scala/RelationType` basic building blocks in ACQ
- `src/main/scala/xxxJob` entry class for specific job 
- `src/main/scala/xxxProcessFunctions` the implemented ProcessFunction used in xxxJob

## Usage
### Arguments
- path: base path of the input file.
- graph: name of the input file.
- parallelism(Optional): the parallelism value to be set in Flink env, 1 by default.
- n(Optional): filter condition value, -1 by default.
- fullEnumEnable(Optional): enable for full enumeration, false by default.
- deltaEnumEnable(Optional): enable for delta enumeration, false by default.

### Input File Format
```
For graph input files, each row should be
+,f1,f2,...,fn      for insertion
-,f1,f2,...,fn      for deletion
* (a single star)   for full enumeration               

For snb input files, each row should be
+|R|f1|f2|...|fn    for insertion
+|R|f1|f2|...|fn    for deletion
* (a single star)   for full enumeration  
R indicates the name of relation, such as TA(tag), ME(message), ...
```

### Run in MiniCluster(in IDE)
```
just click the run button in your IDE and use your desired Job as entry class.
```

### Run in MiniCluster(outside IDE)
compile and build an executable jar.
```shell
mvn clean package -DskipTests=true
```
then run the job using the following command
```shell
java -cp target/ACQ-1.0-SNAPSHOT.jar {job_name} --path {base_path} --graph {file_name}
```

### Run in Flink Standalone Cluster
compile and build an executable jar.
```shell
mvn clean package -DskipTests=true
```
Make sure you have launched the Flink cluster successfully.
check the Flink UI at http://localhost:8081/#/overview

Change the directory into `flink-1.13.x/bin`, run the following command
```shell
./flink run -d -c {job_name} /path/to/ACQ/target/ACQ-1.0-SNAPSHOT.jar --path {base_path} --graph {file_name}
```
it should print the following line
```shell
Job has been submitted with JobID xxx
```
then check your job on http://localhost:8081/#/overview


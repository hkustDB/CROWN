# CROWN

This is an implementation of our paper Change Propagation Without Joins..

## Prerequisites

### Dependencies
- Java 1.8.0_60
- Scala 2.12.12
- Maven 3.8.4
- Flink 1.13(Optional, if you want to submit to a Flink cluster )

## Project Structure
- `src/main/scala/BasedProcessFunctions` base class for process functions
- `src/main/scala/RelationType` basic building blocks in Crown 
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
java -cp target/CROWN-1.0-SNAPSHOT.jar {job_name} --path {base_path} --graph {file_name}
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
./flink run -d -c {job_name} /path/to/CROWN/target/CROWN-1.0-SNAPSHOT.jar --path {base_path} --graph {file_name}
```
it should print the following line
```shell
Job has been submitted with JobID xxx
```
then check your job on http://localhost:8081/#/overview

## How to implement a customized query
### For full query
Take L3 query as example. The query is equivalent to the following SQL
```
    SELECT P1.src AS src, P1.dst AS via1, P3.src AS via2, P3.dst AS dst 
    FROM PATH AS P1, PATH AS P2, PATH AS P3 
    WHERE P1.dst = P2.src AND P2.dst = P3.src
    
    (assuming we have table PATH(src, dst))
```
#### step 1. rewrite the SQL to natural join 
It is equivalent to a natural join between G1(A,B), G2(B,C), and G3(C,D)
#### step 2. choose a (generalized) join tree with the lowest height
The join tree looks like
```
        G2(B,C)
        /   \
    G1(A,B) G3(C,D)
```
#### step 3. create a ProcessFunction class that extends the BasedProcessFunction
Take `L3ProcessFunctions` as example.

Create the `leafRelation` and `middleRelation` that extend `RelationType.Relation` as in `L3ProcessFunctions` for convenience. 
The only difference is the `numChild` parameter. 
```
    class leafRelation(name : String, p_keys : Array[String], next : Relation, override val deltaEnumMode: Int) 
        extends Relation(name, p_keys, next, deltaEnumMode,0)
```

For each relation in the tree, create a variable. In the `initstate` method, create 3 Descriptors as `L3ProcessFunctions`. 
```
    val attributeDescriptor = TypeInformation.of(new TypeHint[Attributes]() {})
    val setAttributeDescriptor = TypeInformation.of(new TypeHint[mutable.HashSet[Attributes]]() {})
    val mapAttributeDescriptor = TypeInformation.of(new TypeHint[mutable.HashMap[Attributes, Int]](){} )
```

Then new instances for each relation with proper name, keys and parent relation. 
The deltaEnumMode follows from the parameter in the constructor of this class.
```
    // G1 is a leaf relation with joinkey=B and middle as its parent
    left = new leafRelation("G1", Array("B"), middle, deltaEnumMode)
    ...
```
Then call `initState` method on all the relations and call `addConnection` method to connect relations to their parents.
```
    left.initState(getRuntimeContext, attributeDescriptor, setAttributeDescriptor)
    ...
    middle.addConnection(Array("B"), left)
```

In the `process` method, dispatch the `Attributes` field of payload to the corresponding relation. 
```
    if (value_raw._1 == "Insert") {
      if (value_raw._2 == "G1") left.insert(value_raw._4)
      ...
    } else {
      if (value_raw._1 == "Delete") {
        if (value_raw._2 == "G1") left.delete(value_raw._4)
        ...
```
If the payload is an "Enumeration" payload, obtain an fullAttrEnumerator from the root of the join tree.
Then enumerate through the enumerator for full enumeration.
```
    if (value_raw._1 == "Enumerate") {
      val t = middle.fullAttrEnumerate(null)
      for (i<- t) i
    }
```

#### step 4. create a scala object as the entry class
Take `L3DistributedJob` as example.

It is basically a simple Flink job. First parse the custom parameters by `ParameterTool`and use `params.get` to retrieve the parameter values.
Then set the Flink configuration(parallelism, memory, etc.) if needed. 
```
    val params: ParameterTool = ParameterTool.fromArgs(args)
    val parallelism = params.get("parallelism", "1").toInt
```
After that, add a source function to the
StreamExecutionEnvironment to read data from your source table. For simplicity, we read it from textfile, but you can have your own source.
Then keyBy the 3rd field of payload and feed the elements to your own ProcessFunction.
```
    env.readTextFile(dataPath).setParallelism(1)    // we wrap it inside the getStream method
    ...
    val result = graphStream.keyBy(i=>i._3).process(new L3ProjectionProcessFunctions(deltaEnumMode))
    ...
```

Note that for parallel execution, we only support a parallelism value in `{1, 2, 4, 8, 16, 32}`
Inside the source function, we split each row by a separator(a `,` in this case). 
```
    val strings = value.split(",")
    val header = strings.head
    val cells: Array[String] = strings.tail
```

Then we create a payload with the action(INSERT/DELETE/ENUMERATION), relationName, partitionKey, attributes, and timestamp.
Note that we may need to broadcast the payload to more than 1 instance of the ProcessFunction(by collecting multiple payloads
with different partitionKeys). Check the `HyperCube` algorithm in the paper for more details. 
```
    // for G1
    for (i <- 0 until rightKeys) {
        ctx.output(graphTag, Payload(action, relation, KeyList(cells(1).toInt%leftKeys*rightKeys+i),
            Attributes(Array[Any](cells(0).toInt, cells(1).toInt), Array[String]("A", "B")), cnt))
    }
```

Finally, add a sink function to sink the output tuples. For performance test, we just use the DiscardingSink to drop all the result tuples. 
```
    result.addSink(new DiscardingSink[String])
```

### For non-full but free-connex query
The only difference with full query is we need to rewrite the join tree to form a connex subset that the relations
in this subset have exactly the fields in projection.

Take `L3ProjectionProcessFunctions` as example.
Consider the natural join between G1(A,B), G2(B,C), and G3(C,D) and projection to fields {B,C}.

The join tree looks like
```
        G2(B,C)
        /   \
    G1(A,B) G3(C,D)
```
Since G2 contains all the fields of {B,C}, we can set the parameter `isOutput` to true in the constructor of G2.
For G1 and G3, set it to false. 
```
    // Note that we set isOutput = true explicitly
    class middleRelation(name : String, p_keys : Array[String], next : Relation, override val deltaEnumMode: Int, 
        isOutput : Boolean = true) extends Relation(name, p_keys, next, deltaEnumMode, 2, isOutput)
```

Then we have an implementation of the equivalent SQL:
```
    SELECT P1.dst AS via1, P3.src AS via2
    FROM PATH AS P1, PATH AS P2, PATH AS P3 
    WHERE P1.dst = P2.src AND P2.dst = P3.src
```

### For aggregation query
Currently, only COUNT is supported.
Take `StarCntProcessFunctions` as example.
The only difference with the non-aggregate version(check `StarProcessFunctions`) is declaring the `leafRelation` extends from `RelationType.AnnotatedRelation`.
```
    // now extends from AnnotatedRelation instead of Relation
    class leafRelation(name : String, p_keys : Array[String], next : Relation, override val deltaEnumMode: Int) 
        extends AnnotatedRelation(name, p_keys, next, deltaEnumMode, 0)
```

Then we have an implementation of the equivalent SQL:
```
    SELECT P1.src, COUNT(*)
    FROM PATH AS P1, PATH AS P2, PATH AS P3, PATH AS P4 
    WHERE P1.src = P2.src AND P2.src = P3.src AND P3.src = P4.src
    GROUP BY P1.src
```
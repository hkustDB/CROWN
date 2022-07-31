import RelationType.{Attributes, Payload}
import Util.{KeyListMap, paraMap}
import org.apache.flink.api.common.typeinfo.TypeInformation
import org.apache.flink.api.java.utils.ParameterTool
import org.apache.flink.configuration.Configuration
import org.apache.flink.streaming.api.TimeCharacteristic
import org.apache.flink.streaming.api.functions.co.CoProcessFunction
import org.apache.flink.streaming.api.functions.sink.{DiscardingSink, PrintSinkFunction, SinkFunction}
import org.apache.flink.streaming.api.scala.{DataStream, StreamExecutionEnvironment, createTypeInformation}
import org.apache.flink.table.api.bridge.scala.StreamTableEnvironment
import org.apache.flink.types.Row
import org.apache.flink.util.Collector

import scala.collection.mutable

object DumbbellFlinkTriangleJob {
  def main(args: Array[String]) {
    // set up the streaming execution environment
    val params: ParameterTool = ParameterTool.fromArgs(args)
    val path = params.get("path", "/tmp")
    val graph = path + "/" + params.get("graph", "graph.dat")

    val parallelism = params.get("parallelism", "1").toInt
    val configuration: Configuration = new Configuration
    // networkMemory default value = "64Mb"
    val networkMemory: Int = Math.max(128, 64 * parallelism)
    configuration.setString("taskmanager.memory.network.min", networkMemory + "Mb")
    configuration.setString("taskmanager.memory.network.max", networkMemory + "Mb")
    val env = StreamExecutionEnvironment.getExecutionEnvironment
    env.configure(configuration, this.getClass.getClassLoader)

    val fullEnumEnable = params.get("fullEnumEnable", "true") == "true"
    val deltaEnumEnable = params.get("deltaEnumEnable", "false") == "true"

    env.setParallelism(parallelism)
    env.setStreamTimeCharacteristic(TimeCharacteristic.EventTime)
    var executionConfig = env.getConfig
    executionConfig.enableObjectReuse()
    val tEnv = StreamTableEnvironment.create(env)

    val triangleStream = getTriangleStream(tEnv, graph)
    val middleStream = getMiddleStream(env, graph)
    val payloads = middleStream.connect(triangleStream).process(new CoProcessFunction[String, (Boolean, Row), Payload] {
      val parallel : Int = env.getParallelism
      val KeyList : List[Int] = KeyListMap.getOrElse(parallel, throw new Exception(s" $parallel not Support"))
      val keys : (Int, Int) = paraMap.getOrElse(parallel, throw new Exception(s" $parallel not Support"))
      val leftKeys = keys._1
      val rightKeys = keys._2

      override def processElement1(value: String, ctx: CoProcessFunction[String, (Boolean, Row), Payload]#Context, out: Collector[Payload]): Unit = {
        collectMiddlePayload(value, out)
      }

      override def processElement2(value: (Boolean, Row), ctx: CoProcessFunction[String, (Boolean, Row), Payload]#Context, out: Collector[Payload]): Unit = {
        collectTrianglePayload(value, out)
      }

      def collectMiddlePayload(value: String, out: Collector[Payload]): Unit = {
        val action = "Insert"
        val fields = value.split(",")
        val payload = Payload(action, "middle", KeyList(fields(0).toInt % leftKeys * rightKeys + fields(1).toInt % rightKeys),
          Attributes(Array[Any](
            fields(0).toInt,
            fields(1).toInt), Array[String]("C", "D")), 0)
        out.collect(payload)

      }

      def collectTrianglePayload(value: (Boolean, Row), out: Collector[Payload]): Unit = {
        val action = if (value._1) "Insert" else "Delete"
        for (i <- 0 until rightKeys) {
          out.collect(Payload(action, "left", KeyList(value._2.getField(2).asInstanceOf[Int] % leftKeys * rightKeys + i),
            Attributes(Array[Any](
              value._2.getField(0).asInstanceOf[Int],
              value._2.getField(1).asInstanceOf[Int],
              value._2.getField(2).asInstanceOf[Int]), Array[String]("A", "B", "C")), 0))
        }

        for (i <- 0 until leftKeys) {
          out.collect(Payload(action, "right", KeyList(i * rightKeys + value._2.getField(0).asInstanceOf[Int] % rightKeys),
            Attributes(Array[Any](
              value._2.getField(0).asInstanceOf[Int],
              value._2.getField(1).asInstanceOf[Int],
              value._2.getField(2).asInstanceOf[Int]), Array[String]("D", "E", "F")), 0))
        }
      }
    })
    val deltaEnumMode = if (deltaEnumEnable) 0 /* enum and drop */ else 4 /* do nothing */
    val result = payloads.keyBy(i=>i._3).process(new DumbbellFlinkTriangleProcessFunction(deltaEnumMode))
    result.addSink(new DiscardingSink[String]())
    // execute program
    env.execute("Dumbbell Program")
  }

  def getTriangleStream(tEnv: StreamTableEnvironment, path: String): DataStream[(Boolean, Row)] = {
    val ddl =
      s"""
         |CREATE TABLE Graph (
         |    src INT,
         |    dst INT
         |) WITH (
         |    'connector' = 'filesystem',
         |    'path' = '$path',
         |    'format' = 'csv'
         |)
         |""".stripMargin
    tEnv.executeSql(ddl)
    val query =
      """
        |SELECT A.src AS t1, B.src AS t2, C.src AS t3
        |FROM Graph AS A, Graph AS B, Graph AS C
        |WHERE A.dst = B.src AND B.dst = C.src AND C.dst = A.src
        |""".stripMargin
    val triangle = tEnv.sqlQuery(query)
    tEnv.toRetractStream(triangle)(TypeInformation.of(classOf[Row]))
  }

  def getMiddleStream(env: StreamExecutionEnvironment, path: String): DataStream[String] = {
    env.readTextFile(path)
  }
}

import RelationType.{Attributes, Payload}
import org.apache.flink.api.java.utils.ParameterTool
import org.apache.flink.configuration.Configuration
import org.apache.flink.streaming.api.functions.ProcessFunction
import org.apache.flink.streaming.api.functions.sink.DiscardingSink
import org.apache.flink.streaming.api.scala._
import org.apache.flink.util.Collector

object L2Job {

  val graphTag: OutputTag[Payload] = OutputTag[Payload]("graph")

  def main(args: Array[String]) {
    // set up the streaming execution environment
    val params: ParameterTool = ParameterTool.fromArgs(args)

    val path = params.get("path", "")
    val graphName = params.get("graph", "soc-bitcoin.bak")
    val inputpath = path + "/" + graphName

    val configuration: Configuration = new Configuration
    // L2Job can only have parallelism 1
    val parallelism = 1
    // networkMemory default value = "64Mb"
    val networkMemory: Int = Math.max(128, 64 * parallelism)
    configuration.setString("taskmanager.memory.network.min", networkMemory + "Mb")
    configuration.setString("taskmanager.memory.network.max", networkMemory + "Mb")
    val env = StreamExecutionEnvironment.getExecutionEnvironment
    env.configure(configuration, this.getClass.getClassLoader)
    env.setParallelism(parallelism)

    var executionConfig = env.getConfig
    executionConfig.enableObjectReuse()

    val fullEnumEnable = params.get("fullEnumEnable", "false") == "true"
    val deltaEnumEnable = params.get("deltaEnumEnable", "false") == "true"

    val inputStream : DataStream[Payload] = getStream(env,inputpath, fullEnumEnable)

    val graphStream : DataStream[Payload] = inputStream.getSideOutput(graphTag)

    val deltaEnumMode = if (deltaEnumEnable) 0 /* enum and drop */ else 4 /* do nothing */
    val result = graphStream.keyBy(i=>i._3).process(new L2ProcessFunctions(deltaEnumMode)).addSink(new DiscardingSink[String])
    // execute program
    env.execute("Line 2 Program")
  }

  private def getStream(env: StreamExecutionEnvironment, dataPath: String, fullEnumEnable: Boolean):
  DataStream[Payload] = {
    val data = env.readTextFile(dataPath).setParallelism(1)

    var cnt: Long = 0
    val T : DataStream[Payload] = data
      .process( new ProcessFunction[String, Payload] {
        override def processElement(value: String, ctx: ProcessFunction[String, Payload]#Context, out: Collector[Payload]): Unit = {
          val strings = value.split(",")
          val header = strings.head
          val cells: Array[String] = strings.tail

          var relation = ""
          var action = ""
          header match {
            case "+" =>
              relation = "G1"
              action = "Insert"
              cnt = cnt + 1
              ctx.output(graphTag, Payload(action, relation, 0.asInstanceOf[Any],
                Attributes(Array[Any](cells(0).toInt, cells(1).toInt), Array[String]("A","B")), cnt))
              relation = "G2"
              ctx.output(graphTag, Payload(action, relation, 0.asInstanceOf[Any],
                Attributes(Array[Any](cells(0).toInt, cells(1).toInt), Array[String]("B","C")), cnt))
            case "-" =>
              action = "Delete"
              relation = "G1"
              cnt = cnt + 1
              ctx.output(graphTag, Payload(action, relation, 0.asInstanceOf[Any],
                Attributes(Array[Any](cells(0).toInt, cells(1).toInt), Array[String]("A","B")), cnt))
              relation = "G2"
              ctx.output(graphTag, Payload(action, relation, 0.asInstanceOf[Any],
                Attributes(Array[Any](cells(0).toInt, cells(1).toInt), Array[String]("B","C")), cnt))
            case "*" if fullEnumEnable =>
              println("trigger full enum at cnt = " + cnt)
              ctx.output(graphTag, Payload("Enumerate", "", 0.asInstanceOf[Any], Attributes(Array(), Array()), cnt))
            case _ =>
          }
        }
      }).setParallelism(1)
      val restDS = T
    restDS
  }
}

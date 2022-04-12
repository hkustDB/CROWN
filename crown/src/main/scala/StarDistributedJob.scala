import RelationType.{Attributes, Payload}
import Util.{KeyListMap, paraMap}
import org.apache.flink.api.java.utils.ParameterTool
import org.apache.flink.configuration.Configuration
import org.apache.flink.streaming.api.TimeCharacteristic
import org.apache.flink.streaming.api.functions.ProcessFunction
import org.apache.flink.streaming.api.functions.sink.DiscardingSink
import org.apache.flink.streaming.api.scala._
import org.apache.flink.util.Collector


object StarDistributedJob {

  val graphTag: OutputTag[Payload] = OutputTag[Payload]("graph")
  var nFilter : Long = -1
  def main(args: Array[String]) {
    // set up the streaming execution environment
    val params: ParameterTool = ParameterTool.fromArgs(args)
    val path = params.get("path", "")
    val graphName = params.get("graph", "soc-bitcoin.bak")

    val parallelism = params.get("parallelism", "1").toInt
    val configuration: Configuration = new Configuration
    // networkMemory default value = "64Mb"
    val networkMemory: Int = Math.max(128, 64 * parallelism)
    configuration.setString("taskmanager.memory.network.min", networkMemory + "Mb")
    configuration.setString("taskmanager.memory.network.max", networkMemory + "Mb")
    val env = StreamExecutionEnvironment.getExecutionEnvironment
    env.configure(configuration, this.getClass.getClassLoader)
    env.setParallelism(parallelism)

    val inputpath = path + "/" + graphName
    val outputpath = path+ "/star.csv"
    nFilter = params.get("n", "-1").toLong
    env.setStreamTimeCharacteristic(TimeCharacteristic.EventTime)
    var executionConfig = env.getConfig
    executionConfig.enableObjectReuse()

    val fullEnumEnable = params.get("fullEnumEnable", "false") == "true"
    val deltaEnumEnable = params.get("deltaEnumEnable", "false") == "true"

    val inputStream : DataStream[Payload] = getStream(env,inputpath,fullEnumEnable)
    val graphStream : DataStream[Payload] = inputStream.getSideOutput(graphTag)

    val deltaEnumMode = if (deltaEnumEnable) 0 /* enum and drop */ else 4 /* do nothing */
    val result = graphStream.keyBy(i=>i._3).process(new StarProcessFunctions(deltaEnumMode))
    result.addSink(new DiscardingSink[String])
    // execute program
    env.execute("Star Program")
  }
  private def getStream(env: StreamExecutionEnvironment, dataPath: String, fullEnumEnable: Boolean):
  DataStream[Payload] = {
    val parallel : Int = env.getParallelism
    val KeyList : List[Int] = KeyListMap.getOrElse(parallel, throw new Exception(s" $parallel not Support"))

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
          def outcollect() : Unit = {
            relation = "R1"
            cnt = cnt + 1
            ctx.output(graphTag, Payload(action, relation, KeyList(cells(0).toInt % parallel).asInstanceOf[Any],
              Attributes(Array[Any](cells(0).toInt, cells(1).toInt), Array[String]("A", "B")), cnt))
            relation = "R2"
            ctx.output(graphTag, Payload(action, relation, KeyList(cells(0).toInt % parallel).asInstanceOf[Any],
              Attributes(Array[Any](cells(0).toInt, cells(1).toInt), Array[String]("A", "C")), cnt))
            relation = "R3"
            ctx.output(graphTag, Payload(action, relation, KeyList(cells(0).toInt % parallel).asInstanceOf[Any],
              Attributes(Array[Any](cells(0).toInt, cells(1).toInt), Array[String]("A", "D")), cnt))
            relation = "R4"
            if (cells(1).toInt > nFilter)
              ctx.output(graphTag, Payload(action, relation, KeyList(cells(0).toInt % parallel).asInstanceOf[Any],
                Attributes(Array[Any](cells(0).toInt, cells(1).toInt), Array[String]("A", "E")), cnt))
          }

          header match {
            case "+" =>
              action = "Insert"
              outcollect()
            case "-" =>
              action = "Delete"
              outcollect()
            case "*" if fullEnumEnable =>
              println("trigger full enum at cnt = " + cnt)
              for (i <- (0 until parallel)) {
                ctx.output(graphTag, Payload("Enumerate", "", KeyList(i).asInstanceOf[Any], Attributes(Array(), Array()), cnt))
              }
            case _ =>
          }
        }
      }).setParallelism(1)
      val restDS = T
    restDS
  }
}

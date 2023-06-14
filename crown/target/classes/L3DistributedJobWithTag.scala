import RelationType.{Attributes, Payload}
import Util.{KeyListMap, paraMap}
import org.apache.flink.api.java.utils.ParameterTool
import org.apache.flink.configuration.Configuration
import org.apache.flink.streaming.api.TimeCharacteristic
import org.apache.flink.streaming.api.functions.ProcessFunction
import org.apache.flink.streaming.api.functions.sink.DiscardingSink
import org.apache.flink.streaming.api.scala._
import org.apache.flink.util.Collector

object L3DistributedJobWithTag {

  val graphTag: OutputTag[Payload] = OutputTag[Payload]("graph")
  var nFilter : Long= -1
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

    val fullEnumEnable = params.get("fullEnumEnable", "false") == "true"
    val deltaEnumEnable = params.get("deltaEnumEnable", "false") == "true"

    env.setParallelism(parallelism)
    nFilter = params.get("n", "-1").toLong
    val inputpath = path + "/" + graphName
    env.setStreamTimeCharacteristic(TimeCharacteristic.EventTime)
    var executionConfig = env.getConfig
    executionConfig.enableObjectReuse()
    val inputStream : DataStream[Payload] = getStream(env, inputpath, fullEnumEnable)

    val graphStream : DataStream[Payload] = inputStream.getSideOutput(graphTag)

    val deltaEnumMode = if (deltaEnumEnable) 0 /* enum and drop */ else 4 /* do nothing */
    val result = graphStream.keyBy(i=>i._3).process(new L3ProcessFunctions(deltaEnumMode))
    result.addSink(new DiscardingSink[String])
    // execute program
    env.execute("Line 3 Program")
  }
  private def getStream(env: StreamExecutionEnvironment, dataPath: String, fullEnumEnable: Boolean):
  DataStream[Payload] = {
    val parallel : Int = env.getParallelism
    val KeyList : List[Int] = KeyListMap.getOrElse(parallel, throw new Exception(s" $parallel not Support"))
    val keys : (Int, Int) = paraMap.getOrElse(parallel, throw new Exception(s" $parallel not Support"))
    val leftKeys = keys._1
    val rightKeys = keys._2

    val data = env.readTextFile(dataPath).setParallelism(1)

    val format = new java.text.SimpleDateFormat("yyyy-MM-dd")
    var cnt: Long = 0
    val T : DataStream[Payload] = data
      .process( new ProcessFunction[String, Payload] {
        override def processElement(value: String, ctx: ProcessFunction[String, Payload]#Context, out: Collector[Payload]): Unit = {
          val strings = value.split(",")
          val header = strings.head
          val fields: Array[String] = strings.tail
          var relation = ""
          var action = ""
          def outcollect() : Unit = {
            val cells = fields.tail
            relation = fields.head
            cnt = cnt + 1
            relation match {
              case "G1" =>
                for (i <- 0 until rightKeys) {
                  ctx.output(graphTag, Payload(action, relation, KeyList(cells(1).toInt%leftKeys*rightKeys+i),
                    Attributes(Array[Any](cells(0).toInt, cells(1).toInt), Array[String]("A", "B")), cnt))
                }
              case "G2" =>
                ctx.output(graphTag, Payload(action, relation, KeyList(cells(0).toInt%leftKeys*rightKeys+cells(1).toInt%rightKeys).asInstanceOf[Any],
                  Attributes(Array[Any](cells(0).toInt, cells(1).toInt), Array[String]("B","C")), cnt))
              case "G3" =>
                if (cells(1).toInt > nFilter)
                  for (i <- 0 until leftKeys) {
                    ctx.output(graphTag, Payload(action, relation, KeyList(i*rightKeys+cells(0).toInt%rightKeys).asInstanceOf[Any],
                      Attributes(Array[Any](cells(0).toInt, cells(1).toInt), Array[String]("C", "D")), cnt))
                  }
            }
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
              for (left <- (0 until leftKeys)) {
                for (right <- (0 until rightKeys)) {
                  ctx.output(graphTag, Payload("Enumerate", "", KeyList(left * rightKeys + right).asInstanceOf[Any], Attributes(Array(), Array()), cnt))
                }
              }
            case _ =>
          }
        }
      }).setParallelism(1)
      val restDS = T
    restDS
  }
}

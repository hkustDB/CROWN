import RelationType.{Attributes, Payload}
import Util.KeyListMap
import org.apache.flink.api.java.utils.ParameterTool
import org.apache.flink.configuration.Configuration
import org.apache.flink.streaming.api.TimeCharacteristic
import org.apache.flink.streaming.api.functions.ProcessFunction
import org.apache.flink.streaming.api.functions.sink.DiscardingSink
import org.apache.flink.streaming.api.scala._
import org.apache.flink.util.Collector


object SNBQ1Job {

  val graphTag: OutputTag[Payload] = OutputTag[Payload]("graph")
  var nFilter : Long = -1
  def main(args: Array[String]) {
    // set up the streaming execution environment
    val params: ParameterTool = ParameterTool.fromArgs(args)
    val path = params.get("path", "")
    val graphName = params.get("graph", "ms_snb_output.csv")
    val parallelism = params.get("parallelism", "1").toInt
    val configuration: Configuration = new Configuration
    // networkMemory default value = "64Mb"
    val networkMemory: Int = Math.max(128, 64 * parallelism)
    configuration.setString("taskmanager.memory.network.min", networkMemory + "Mb")
    configuration.setString("taskmanager.memory.network.max", networkMemory + "Mb")
    val env = StreamExecutionEnvironment.getExecutionEnvironment
    env.configure(configuration, this.getClass.getClassLoader)
    env.setParallelism(parallelism)

    nFilter = params.get("n", "-1").toLong
    val inputpath = path + "/" + graphName
    val outputpath = path+ "/SNBQ1.csv"
    env.setStreamTimeCharacteristic(TimeCharacteristic.EventTime)
    var executionConfig = env.getConfig
    executionConfig.enableObjectReuse()

    val fullEnumEnable = params.get("fullEnumEnable", "false") == "true"
    val deltaEnumEnable = params.get("deltaEnumEnable", "false") == "true"

    val inputStream : DataStream[Payload] = getStream(env,inputpath,fullEnumEnable)

    val deltaEnumMode = if (deltaEnumEnable) 0 /* enum and drop */ else 4 /* do nothing */
    val result = inputStream.keyBy(i=>i._3).process(new SNBQ1ProcessFunctions(deltaEnumMode))
    result.addSink(new DiscardingSink[String])
    // execute program
    env.execute("SNB Q1 Program")
  }

  private def getStream(env: StreamExecutionEnvironment, dataPath: String, fullEnumEnable: Boolean):
  DataStream[Payload] = {
    val data = env.readTextFile(dataPath).setParallelism(1)

    val parallel : Int = env.getParallelism
    var cnt: Long = 0
    val KeyList : List[Int] = KeyListMap.getOrElse(parallel, throw new Exception(s" $parallel not Support"))

    val T : DataStream[Payload] = data
      .process( new ProcessFunction[String, Payload] {
        override def processElement(value: String, ctx: ProcessFunction[String, Payload]#Context, out: Collector[Payload]): Unit = {
          cnt = cnt + 1
          val strings = value.split("\\|")
          val op = strings(0)

          var relation = ""
          var action = ""
          def outcollect() : Unit = {
            val indicator = strings(1)
            val cells = strings.slice(2, strings.length)
            indicator match {
              case "ME" =>
                relation = "message"
                out.collect(Payload(action, relation, KeyList((cells(8).toLong % parallel).toInt),
                    Attributes(Array[Any](cells(1).toLong, cells(8).toLong), Array[String]("MessageID", "IDB")), cnt))
              case "KN" =>
                relation = "knows"
                out.collect(Payload(action, relation, KeyList((cells(2).toLong % parallel).toInt),
                  Attributes(Array[Any](cells(1).toLong, cells(2).toLong), Array[String]("IDA", "IDB")), cnt))
              case "PE" =>
                relation = "person"
                out.collect(Payload(action, relation, KeyList((cells(1).toLong % parallel).toInt),
                  Attributes(Array[Any](cells(1).toLong, cells(2), cells(3)), Array[String]("IDB", "firstName", "secondName")), cnt))
              case _ =>
                cnt = cnt - 1
            }
          }

          op match {
            case "+" =>
              action = "Insert"
              outcollect()
            case "-" =>
              action = "Delete"
              outcollect()
            case "*" if fullEnumEnable =>
              println("trigger full enum at cnt = " + cnt)
              for (i <- (0 until parallel)) {
                out.collect(Payload("Enumerate", "", KeyList(i).asInstanceOf[Any], Attributes(Array(), Array()), cnt))
              }
            case _ =>
          }
        }
      }).setParallelism(1)
      val restDS = T
    restDS
  }
}

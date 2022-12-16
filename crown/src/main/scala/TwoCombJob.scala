import RelationType.{Attributes, Payload}
import org.apache.flink.api.java.utils.ParameterTool
import org.apache.flink.configuration.Configuration
import org.apache.flink.streaming.api.functions.ProcessFunction
import org.apache.flink.streaming.api.functions.sink.DiscardingSink
import org.apache.flink.streaming.api.scala.{DataStream, StreamExecutionEnvironment}
import org.apache.flink.streaming.api.scala._
import org.apache.flink.util.Collector

object TwoCombJob {
    def main(args: Array[String]) {
        // set up the streaming execution environment
        val params: ParameterTool = ParameterTool.fromArgs(args)
        val path = params.get("path", "")
        val graphName = params.get("graph", "soc-bitcoin.bak")
        val inputpath = path + "/" + graphName

        val configuration: Configuration = new Configuration
        // L3Job can only have parallelism 1
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

        val inputStream : DataStream[Payload] = getStream(env, inputpath, fullEnumEnable)

        val deltaEnumMode = if (deltaEnumEnable) 0 /* enum and drop */ else 4 /* do nothing */
        val result = inputStream.keyBy(i=>i._3).process(new TwoCombProcessFunctions(deltaEnumMode))//.writeAsText(outputpath, WriteMode.OVERWRITE)
        result.addSink(new DiscardingSink[String])
        // execute program
        env.execute("Line 3 Program")
    }

    private def getStream(env: StreamExecutionEnvironment, dataPath: String, fullEnumEnable: Boolean):
    DataStream[Payload] = {
        val data = env.readTextFile(dataPath).setParallelism(1)

        var cnt: Long = 0
        val T : DataStream[Payload] = data
            .process( new ProcessFunction[String, Payload] {
                override def processElement(value: String, ctx: ProcessFunction[String, Payload]#Context, out: Collector[Payload]): Unit = {
                    val strings = value.split(",")
                    val header = strings(0)

                    var relation = ""
                    var action = ""
                    header match {
                        case "+" =>
                            val table = strings(1)
                            val cells: Array[String] = strings.tail.tail
                            cnt = cnt + 1
                            action = "Insert"
                            if (table == "G") {
                                relation = "G1"
                                out.collect(Payload(action, relation, 0.asInstanceOf[Any],
                                    Attributes(Array[Any](cells(0).toInt, cells(1).toInt), Array[String]("A", "B")), cnt))
                                relation = "G2"
                                out.collect(Payload(action, relation, 0.asInstanceOf[Any],
                                    Attributes(Array[Any](cells(0).toInt, cells(1).toInt), Array[String]("B", "C")), cnt))
                                relation = "G3"
                                out.collect(Payload(action, relation, 0.asInstanceOf[Any],
                                    Attributes(Array[Any](cells(0).toInt, cells(1).toInt), Array[String]("C", "D")), cnt))
                            } else if (table == "V1") {
                                relation = "V1"
                                out.collect(Payload(action, relation, 0.asInstanceOf[Any],
                                    Attributes(Array[Any](cells(0).toInt), Array[String]("A")), cnt))
                            } else {
                                relation = "V2"
                                out.collect(Payload(action, relation, 0.asInstanceOf[Any],
                                    Attributes(Array[Any](cells(0).toInt), Array[String]("D")), cnt))
                            }
                        case "-" =>
                            val table = strings(1)
                            val cells: Array[String] = strings.tail.tail
                            cnt = cnt + 1
                            action = "Delete"
                            if (table == "G") {
                                relation = "G1"
                                out.collect(Payload(action, relation, 0.asInstanceOf[Any],
                                    Attributes(Array[Any](cells(0).toInt, cells(1).toInt), Array[String]("A", "B")), cnt))
                                relation = "G2"
                                out.collect(Payload(action, relation, 0.asInstanceOf[Any],
                                    Attributes(Array[Any](cells(0).toInt, cells(1).toInt), Array[String]("B", "C")), cnt))
                                relation = "G3"
                                out.collect(Payload(action, relation, 0.asInstanceOf[Any],
                                    Attributes(Array[Any](cells(0).toInt, cells(1).toInt), Array[String]("C", "D")), cnt))
                            } else if (table == "V1") {
                                relation = "V1"
                                out.collect(Payload(action, relation, 0.asInstanceOf[Any],
                                    Attributes(Array[Any](cells(0).toInt), Array[String]("A")), cnt))
                            } else {
                                relation = "V2"
                                out.collect(Payload(action, relation, 0.asInstanceOf[Any],
                                    Attributes(Array[Any](cells(0).toInt), Array[String]("D")), cnt))
                            }
                        case "*" if fullEnumEnable =>
                            println("trigger full enum at cnt = " + cnt)
                            out.collect(Payload("Enumerate", "", 0.asInstanceOf[Any], Attributes(Array(), Array()), cnt))
                        case _ =>
                    }
                }
            }).setParallelism(1)
        val restDS = T
        restDS
    }
}
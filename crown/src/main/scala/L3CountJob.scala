import RelationType.{Attributes, Payload}
import org.apache.flink.configuration.Configuration
import org.apache.flink.streaming.api.functions.ProcessFunction
import org.apache.flink.streaming.api.functions.sink.PrintSinkFunction
import org.apache.flink.streaming.api.scala._
import org.apache.flink.util.Collector

object L3CountJob {
    def main(args: Array[String]) {
        val configuration: Configuration = new Configuration
        val networkMemory: Int = Math.max(128, 64 * 1)
        configuration.setString("taskmanager.memory.network.min", networkMemory + "Mb")
        configuration.setString("taskmanager.memory.network.max", networkMemory + "Mb")
        val env = StreamExecutionEnvironment.getExecutionEnvironment
        env.configure(configuration, this.getClass.getClassLoader)
        env.setParallelism(1)

        val inputpath = "/path/to/graph.csv"
        val fullEnumEnable = true
        val graphStream: DataStream[Payload] = getStream(env, inputpath, fullEnumEnable)

        val deltaEnumMode = 4
        val result = graphStream.keyBy(i => i._3).process(new L3CountProcessFunction(deltaEnumMode))
        result.addSink(new PrintSinkFunction[String]())
        env.execute("L3 Count Program")
    }

    private def getStream(env: StreamExecutionEnvironment, dataPath: String, fullEnumEnable: Boolean):
    DataStream[Payload] = {
        val data = env.readTextFile(dataPath).setParallelism(1)

        var cnt: Long = 0
        val ds: DataStream[Payload] = data
            .process(new ProcessFunction[String, Payload] {
                override def processElement(value: String, ctx: ProcessFunction[String, Payload]#Context, out: Collector[Payload]): Unit = {
                    val strings = value.split("\\|")
                    val header = strings.head
                    val cells: Array[String] = strings.tail

                    var relation = ""
                    var action = ""
                    header match {
                        case "+" =>
                            relation = "R1"
                            action = "Insert"
                            cnt = cnt + 1
                            out.collect(Payload(action, relation, 0.asInstanceOf[Any],
                                Attributes(Array[Any](cells(0).toInt, cells(1).toInt), Array[String]("A", "B")), cnt))
                            relation = "R2"
                            out.collect(Payload(action, relation, 0.asInstanceOf[Any],
                                Attributes(Array[Any](cells(0).toInt, cells(1).toInt, 0), Array[String]("B", "C", "E")), cnt))
                            relation = "R3"
                            out.collect(Payload(action, relation, 0.asInstanceOf[Any],
                                Attributes(Array[Any](cells(0).toInt, cells(1).toInt), Array[String]("C", "D")), cnt))
                        case "-" =>
                            action = "Delete"
                            relation = "R1"
                            cnt = cnt + 1
                            out.collect(Payload(action, relation, 0.asInstanceOf[Any],
                                Attributes(Array[Any](cells(0).toInt, cells(1).toInt), Array[String]("A", "B")), cnt))
                            relation = "R2"
                            out.collect(Payload(action, relation, 0.asInstanceOf[Any],
                                Attributes(Array[Any](cells(0).toInt, cells(1).toInt, 0), Array[String]("B", "C", "E")), cnt))
                            relation = "R3"
                            out.collect(Payload(action, relation, 0.asInstanceOf[Any],
                                Attributes(Array[Any](cells(0).toInt, cells(1).toInt), Array[String]("C", "D")), cnt))
                        case "*" if fullEnumEnable =>
                            out.collect(Payload("Enumerate", "", 0.asInstanceOf[Any], Attributes(Array(), Array()), cnt))
                        case _ =>
                    }
                }
            }).setParallelism(1)
        ds
    }
}

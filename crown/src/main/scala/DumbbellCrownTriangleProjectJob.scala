import RelationType.{Attributes, Payload}
import Util.{KeyListMap, paraMap}
import org.apache.flink.api.common.functions.FlatMapFunction
import org.apache.flink.api.java.utils.ParameterTool
import org.apache.flink.configuration.Configuration
import org.apache.flink.streaming.api.TimeCharacteristic
import org.apache.flink.streaming.api.functions.sink.PrintSinkFunction
import org.apache.flink.streaming.api.scala.{DataStream, StreamExecutionEnvironment, createTypeInformation}
import org.apache.flink.util.Collector

object DumbbellCrownTriangleProjectJob {
    def main(args: Array[String]): Unit = {
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

        val deltaEnumMode = if (deltaEnumEnable) 0 /* enum and drop */ else 4 /* do nothing */
        val nFilter : Long = params.get("n", "-1").toLong

        getStream(env, graph, fullEnumEnable, nFilter)
            .keyBy(p => p._3)
            .process(new DumbbellCrownTriangleProjectProcessFunction(deltaEnumMode))
            .addSink(new PrintSinkFunction[String]())
        env.execute()
    }

    def getStream(env: StreamExecutionEnvironment, path: String, fullEnumEnable: Boolean, filter: Long): DataStream[Payload] = {
        val parallel : Int = env.getParallelism
        val keyList : List[Int] = KeyListMap.getOrElse(parallel, throw new Exception(s" $parallel not Support"))
        val keys : (Int, Int) = paraMap.getOrElse(parallel, throw new Exception(s" $parallel not Support"))
        val leftKeys = keys._1
        val rightKeys = keys._2

        env.readTextFile(path).setParallelism(1).flatMap(new FlatMapFunction[String, Payload]() {
            override def flatMap(value: String, out: Collector[Payload]): Unit = {
                val fields = value.split(",")
                if (fields.head.head.isDigit) {
                    // for insert only without '+' at the beginning of every line
                    val src = fields(0).toInt
                    val dst = fields(1).toInt
                    val fieldsArray: Array[Any] = Array(src, dst)
                    collect(out, "Insert", fieldsArray, keyList, leftKeys, rightKeys, filter)
                } else {
                    fields.head match {
                        case "+" =>
                            val src = fields(1).toInt
                            val dst = fields(2).toInt
                            val fieldsArray: Array[Any] = Array(src, dst)
                            collect(out, "Insert", fieldsArray, keyList, leftKeys, rightKeys, filter)
                        case "-" =>
                            val src = fields(1).toInt
                            val dst = fields(2).toInt
                            val fieldsArray: Array[Any] = Array(src, dst)
                            collect(out, "Delete", fieldsArray, keyList, leftKeys, rightKeys, filter)
                        case "*" =>
                            if (fullEnumEnable)
                                out.collect(Payload("Enumerate", "middle", 0, Attributes(Array(), Array()), 0))
                    }
                }
            }
        }).setParallelism(1)
    }

    def collect(out: Collector[Payload], action: String, fieldsArray: Array[Any], keyList : List[Int], leftKeys: Int, rightKeys: Int, filter: Long): Unit = {
        val f0 = fieldsArray(0).asInstanceOf[Int]
        val f1 = fieldsArray(1).asInstanceOf[Int]

        out.collect(Payload(action, "middle",
            keyList(f0%leftKeys*rightKeys+f1%rightKeys),
            Attributes(fieldsArray, Array("C", "D")), 0))

        if (f0 > filter && f1 > filter) {
            for (i <- 0 until rightKeys) {
                out.collect(Payload(action, "left", keyList(f1 % leftKeys * rightKeys + i), Attributes(fieldsArray, Array("B", "C")), 0))
                out.collect(Payload(action, "left", keyList(f0 % leftKeys * rightKeys + i), Attributes(fieldsArray, Array("C", "A")), 0))
            }

            for (i <- 0 until leftKeys) {
                out.collect(Payload(action, "right", keyList(i * rightKeys + f0 % rightKeys), Attributes(fieldsArray, Array("D", "E")), 0))
                out.collect(Payload(action, "right", keyList(i * rightKeys + f1 % rightKeys), Attributes(fieldsArray, Array("F", "D")), 0))
            }

            for (k <- keyList) {
                out.collect(Payload(action, "left", k, Attributes(fieldsArray, Array("A", "B")), 0))
                out.collect(Payload(action, "right", k, Attributes(fieldsArray, Array("E", "F")), 0))
            }
        }
    }
}

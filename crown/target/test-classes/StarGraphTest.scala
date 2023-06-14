import RelationType.{Attributes, Payload}
import org.apache.flink.api.common.typeinfo.{BasicTypeInfo, TypeInformation}
import org.apache.flink.api.java.functions.KeySelector
import org.apache.flink.streaming.util.{KeyedOneInputStreamOperatorTestHarness, ProcessFunctionTestHarnesses}
import org.scalatest._
import org.scalatest.flatspec.AnyFlatSpec

import scala.collection.mutable.ArrayBuffer
import scala.io.Source

class StarGraphTest extends AnyFlatSpec with BeforeAndAfterAllConfigMap {
  var srcFile = ""

  // if fullEnumEnable is ON, full enum will be triggered when we encounter a row begins with '*'
  var fullEnumEnable = false

  var deltaEnumEnable = false

  override def beforeAll(configMap: ConfigMap): Unit = {
    srcFile = configMap.get("srcFile").getOrElse("").asInstanceOf[String]
    fullEnumEnable = configMap.get("fullEnumEnable").getOrElse("false") == "true"
    deltaEnumEnable = configMap.get("deltaEnumEnable").getOrElse("false") == "true"
  }

  "PassThroughProcessFunction" should "forward values" in {

    //instantiate user-defined function
    val deltaEnumMode = if (deltaEnumEnable) 0 /* enum and drop */ else 4 /* do nothing */
    val processFunction = new StarProcessFunctions(deltaEnumMode)

    // wrap user defined function into a the corresponding operator
    val harness = ProcessFunctionTestHarnesses.forKeyedProcessFunction[Any, Payload, String](processFunction, new KeySelector[Payload, Any] {
      override def getKey(value: Payload): Any = value._3}, BasicTypeInfo.INT_TYPE_INFO.asInstanceOf[TypeInformation[Any]])

    var source: Source = null
    val lines = ArrayBuffer[String]()
    try {
      source = Source.fromFile(srcFile)
      source.getLines().foreach(line => lines.append(line))
    } finally {
      source.close()
    }

    // "+,1,2" -> ("Insert", Array(1, 2))
    val rows = lines.map(line => {
      val strings = line.split(",")
      val action = strings(0)
      (action, if (action != "*") Array[Any](strings(1).toInt, strings(2).toInt) else Array[Any]())
    })

    var cnt = 0L
    val start = System.currentTimeMillis()
    for (row <- rows) {
      row._1 match {
        case "+" =>
          cnt = cnt + 1
          feedElements(harness, "Insert", row._2, cnt)
        case "-" =>
          cnt = cnt + 1
          feedElements(harness, "Delete", row._2, cnt)
        case "*" =>
          println("trigger full enum at: " + cnt)
          triggerFullEnumeration(harness, cnt)
      }
    }

    val finish = System.currentTimeMillis()
    info("Execution time: " + ((finish - start) / 1000f).formatted("%.2f"))
  }

  def feedElements(harness: KeyedOneInputStreamOperatorTestHarness[Any, Payload, String], action: String,
                   fields: Array[Any], ts: Long): Unit = {
    harness.processElement(Payload(action, "R1", 0,
      Attributes(fields, Array[String]("A", "B")), 0), ts)
    harness.processElement(Payload(action, "R2", 0,
      Attributes(fields, Array[String]("A", "C")), 0), ts)
    harness.processElement(Payload(action, "R3", 0,
      Attributes(fields, Array[String]("A", "D")), 0), ts)
    harness.processElement(Payload(action, "R4", 0,
      Attributes(fields, Array[String]("A", "E")), 0), ts)
  }

  def triggerFullEnumeration(harness: KeyedOneInputStreamOperatorTestHarness[Any, Payload, String], ts: Long): Unit = {
    harness.processElement(Payload("Enumerate", "", 0,
      Attributes(Array(), Array[String]()), 0), ts)
  }
}

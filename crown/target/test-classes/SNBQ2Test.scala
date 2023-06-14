import RelationType.{Attributes, Payload}
import org.apache.flink.api.common.typeinfo.{BasicTypeInfo, TypeInformation}
import org.apache.flink.api.java.functions.KeySelector
import org.apache.flink.streaming.util.{KeyedOneInputStreamOperatorTestHarness, ProcessFunctionTestHarnesses}
import org.scalatest._
import org.scalatest.flatspec.AnyFlatSpec
import org.scalatest.matchers.should.Matchers

import scala.collection.mutable.ArrayBuffer
import scala.io.Source

class SNBQ2Test extends AnyFlatSpec with BeforeAndAfterAllConfigMap {
  var srcFile = ""

  // if fullEnumEnable is ON, full enum will be triggered when we encounter a row begins with '*'
  var fullEnumEnable = false

  var deltaEnumEnable = false

  override def beforeAll(configMap: ConfigMap): Unit = {
    srcFile = configMap.get("srcFile").getOrElse("").asInstanceOf[String]
    fullEnumEnable = configMap.get("fullEnumEnable").getOrElse("false") == "true"
    deltaEnumEnable = configMap.get("deltaEnumEnable").getOrElse("false") == "true"
  }

  "SNBQ2Test" should "forward values" in {

    //instantiate user-defined function
    val deltaEnumMode = if (deltaEnumEnable) 0 /* enum and drop */ else 4 /* do nothing */
    val processFunction = new SNBQ2ProcessFunctions(deltaEnumMode)

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

    // "+,ME,f1,f2,...,fn" -> ("+", "ME", Array(f1,f2,...,fn))
    val rows = lines.map(line => {
      val strings = line.split(",")
      val action = strings(0)
      if (action != "*") {
        val indicator = strings(1)
        (action, indicator, strings.slice(2, strings.length))
      } else {
        (action, "", Array[String]())
      }
    })

    var cnt = 0L
    val start = System.currentTimeMillis()
    var relation = ""
    var action = ""
    var indicator = ""
    var cells: Array[String] = null

    for (row <- rows) {
      cnt = cnt + 1
      if (row._1 == "+" || row._1 == "-") {
        action = if (row._1 == "+") "Insert" else "Delete"
        indicator = row._2
        cells = row._3
        indicator match {
          case "ME" =>
            relation = "message"
            if (cells.size < 14 || cells(13).isEmpty)
              harness.processElement(Payload(action, relation, 0,
                Attributes(Array[Any](cells(2).toLong, cells(9).toLong), Array[String]("MessageID", "IDC")), cnt), cnt)
          case "TA" =>
            relation = "tag"
            harness.processElement(Payload(action, relation, 0,
              Attributes(Array[Any](cells(0).toLong), Array[String]("TagID")), cnt), cnt)
          case "KN" =>
            relation = "knows1"
            if (cells(2).toLong < 100000) harness.processElement(Payload(action, relation, 0,
              Attributes(Array[Any](cells(2).toLong, cells(3).toLong), Array[String]("IDA", "IDB")), cnt), cnt)
            relation = "knows2"
            harness.processElement(Payload(action, relation, 0,
              Attributes(Array[Any](cells(2).toLong, cells(3).toLong), Array[String]("IDB", "IDC")), cnt), cnt)
          case "MT" =>
            relation = "messageTag"
            harness.processElement(Payload(action, relation, 0,
              Attributes(Array[Any](cells(1).toLong, cells(2).toLong), Array[String]("MessageID", "TagID")), cnt), cnt)
          case _ =>
            cnt = cnt - 1
        }
      } else if (row._1 == "*") {
        println("trigger full enum at: " + cnt)
        triggerFullEnumeration(harness, cnt)
      }
    }

    val finish = System.currentTimeMillis()
    info("Execution time: " + ((finish - start) / 1000f).formatted("%.2f"))
  }

  def triggerFullEnumeration(harness: KeyedOneInputStreamOperatorTestHarness[Any, Payload, String], ts: Long): Unit = {
    harness.processElement(Payload("Enumerate", "", 0,
      Attributes(Array(), Array[String]()), 0), ts)
  }
}

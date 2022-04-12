import RelationType.{Attributes, Payload}
import org.apache.flink.api.common.typeinfo.{BasicTypeInfo, TypeInformation}
import org.apache.flink.api.java.functions.KeySelector
import org.apache.flink.streaming.util.ProcessFunctionTestHarnesses
import org.scalatest._
import org.scalatest.flatspec.AnyFlatSpec
import org.scalatest.matchers.should.Matchers

import scala.collection.mutable
import scala.io.Source


class L1GraphTest extends AnyFlatSpec with BeforeAndAfterAllConfigMap {
  var srcFile = ""

  override def beforeAll(configMap: ConfigMap): Unit = {
    srcFile = configMap.get("srcFile").getOrElse("").asInstanceOf[String]
  }

  "PassThroughProcessFunction" should "forward values" in {

    //instantiate user-defined function
    val processFunction = new L1ProcessFunctions(2)

    // wrap user defined function into a the corresponding operator
    val harness = ProcessFunctionTestHarnesses.forKeyedProcessFunction[Any, Payload, String](processFunction, new KeySelector[Payload, Any] {
      override def getKey(value: Payload): Any = value._3}, BasicTypeInfo.INT_TYPE_INFO.asInstanceOf[TypeInformation[Any]])

    var src = Source.fromFile(srcFile).getLines()
    var cnt = 0L
    for (i <- src) {
      cnt = cnt + 1
      System.out.println(cnt)
      val j = i.split(" ")
      val temp1 = new mutable.HashMap[String, Any]()
      temp1.put("A", j(0).toInt)
      temp1.put("B", j(1).toInt)
      harness.processElement(Payload("Insert", "Left", 0,
        Attributes(Array[Any](j(0).toInt, j(1).toInt), Array[String]("A", "B")), 0), cnt)    }

    src = Source.fromFile(srcFile).getLines()
    cnt = 0L
    for (i <- src) {
      cnt = cnt + 1
      if (cnt == 4) {
        System.out.println(cnt)
      }
      val j = i.split(" ")
      val temp1 = new mutable.HashMap[String, Any]()
      temp1.put("A", j(0).toInt)
      temp1.put("B", j(1).toInt)
      harness.processElement(Payload("Delete", "Left", 0,
        Attributes(Array[Any](j(0).toInt, j(1).toInt), Array[String]("A", "B")), 0), cnt)
    }
  }
}

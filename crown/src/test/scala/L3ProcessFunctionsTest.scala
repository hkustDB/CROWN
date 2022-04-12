import RelationType.{Attributes, Payload}
import org.apache.flink.api.common.typeinfo.{BasicTypeInfo, TypeInformation}
import org.apache.flink.api.java.functions.KeySelector
import org.apache.flink.streaming.util.ProcessFunctionTestHarnesses
import org.scalatest._
import org.scalatest.flatspec.AnyFlatSpec
import org.scalatest.matchers.should.Matchers

import scala.collection.mutable

class L3ProcessFunctionsTest extends AnyFlatSpec with Matchers with BeforeAndAfter{
  "PassThroughProcessFunction" should "forward values" in {

    //instantiate user-defined function
    val processFunction = new L3ProcessFunctions(0)

    // wrap user defined function into a the corresponding operator
    val harness = ProcessFunctionTestHarnesses.forKeyedProcessFunction[Any, Payload, String](processFunction, new KeySelector[Payload, Any] {
      override def getKey(value: Payload): Any = value._3}, BasicTypeInfo.INT_TYPE_INFO.asInstanceOf[TypeInformation[Any]])

    val a = Attributes(Array(1, 2), Array("B", "C"))
    val b = Attributes(Array(1, 3), Array("B", "C"))
    val c = Attributes(Array(1, 1), Array("A", "B"))
    val d = Attributes(Array(2, 2), Array("C", "D"))
    val e = Attributes(Array(2, 1), Array("A", "B"))
    val f = Attributes(Array(1, 2), Array("B", "C"))
    val g = Attributes(Array(3, 1), Array("C", "D"))
    //push (timestamped) elements into the operator (and hence user defined function)
    System.out.println("Update")
    harness.processElement(Payload("Insert", "Middle", 0, a, 0L), 1L)
    System.out.println("Update")
    harness.processElement(Payload("Insert", "Left", 0, c, 0L), 2L)
    harness.processElement(Payload("Insert", "Right", 0, d, 0L), 2L)
    System.out.println("Update")
    harness.processElement(Payload("Insert", "Middle", 0, b, 0L), 3L)
    System.out.println("Update")
    System.out.println("Update")
    harness.processElement(Payload("Insert", "Right", 0, g, 0L), 5L)
    System.out.println("Update")
    harness.processElement(Payload("Delete", "Right", 0, d, 0L), 6L)
    System.out.println("Update")
    harness.processElement(Payload("Delete", "Left", 0, c, 0L), 6L)
  }
}

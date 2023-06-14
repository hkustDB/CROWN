import RelationType.Attributes
import org.scalatest._
import org.scalatest.flatspec.AnyFlatSpec
import org.scalatest.matchers.should.Matchers

import scala.collection.mutable

class AttributesTest extends AnyFlatSpec with Matchers with BeforeAndAfter{
  "Attribute" should "join values" in {
    var temp = new mutable.HashMap[String, Any]()
    temp.put("B", 1)
    temp.put("C", 2)
    val a = Attributes(Array[Any](1, 2), Array[String]("B", "C"))
    temp = new mutable.HashMap[String, Any]()
    temp.put("B", 1)
    temp.put("C", 3)
    val b = Attributes(Array[Any](1, 3), Array[String]("B", "C"))
    temp = new mutable.HashMap[String, Any]()
    temp.put("A", 1)
    temp.put("B", 1)
    val c = Attributes(Array[Any](1, 1), Array[String]("A", "B"))
    val d = a.join(b)
    val e = a.join(c)
    System.out.println(d)
    System.out.println(e)
  }

  "Attribute" should "compute correct hashcode" in {
    val attr1 = Attributes(Array(1,2,3), Array("A","B","C"))
    val attr2 = Attributes(Array(1,2), Array("A","B"))
    val attr3 = Attributes(Array(3,2,1), Array("C","B","A"))

    assert(attr1.hashCode() != attr2.hashCode())
    assert(attr1.hashCode() == attr3.hashCode())
  }
}

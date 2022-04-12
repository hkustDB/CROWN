import BasedProcessFunctions.BasedProcessFunction
import RelationType.{Attributes, GeneralizedRelation, Payload, Relation}
import org.apache.flink.api.common.typeinfo.{TypeHint, TypeInformation}
import org.apache.flink.streaming.api.functions.KeyedProcessFunction
import org.apache.flink.util.Collector

import scala.collection.JavaConverters._
import scala.collection.mutable

class SNBQ3ProcessFunctions(val deltaEnumMode: Int) extends BasedProcessFunction[Any, Payload, String](0, 0, "L3ProcessFunction") {
  var message : middleRelation = null
  var person : leafRelation = null
  var knows2 : middleRelation = null
  var knows1 : leafRelation = null
  var middle : GeneralizedRelation = null
  var outSet : Boolean = false
  /**
   * A function to initial the state as Flink required.
   */
  override def initstate(): Unit = {
    val attributeDescriptor = TypeInformation.of(new TypeHint[Attributes]() {})
    val setAttributeDescriptor = TypeInformation.of(new TypeHint[mutable.HashSet[Attributes]]() {})
    val mapAttributeDescriptor = TypeInformation.of(new TypeHint[mutable.HashMap[Attributes, Int]](){} )

    middle = new GeneralizedRelation("[IDc]", Array("IDC"), null, deltaEnumMode, 2) {}
    message =  new middleRelation("message", Array("IDC"), middle, deltaEnumMode, 1)
    person = new leafRelation("person", Array("IDC"), message, deltaEnumMode)
    knows2 =  new middleRelation("knows2", Array("IDC"), middle, deltaEnumMode, 1)
    knows1 = new leafRelation("knows1", Array("IDB"), knows2, deltaEnumMode)
    knows1.initState(getRuntimeContext, attributeDescriptor, setAttributeDescriptor)
    person.initState(getRuntimeContext, attributeDescriptor, setAttributeDescriptor)
    message.initState(getRuntimeContext, attributeDescriptor, setAttributeDescriptor, mapAttributeDescriptor)
    knows2.initState(getRuntimeContext, attributeDescriptor, setAttributeDescriptor, mapAttributeDescriptor)
    middle.initState(getRuntimeContext, attributeDescriptor, setAttributeDescriptor, mapAttributeDescriptor)
    middle.addConnection(Array("IDC"), message)
    message.addConnection(Array("IDC"), person)
    middle.addConnection(Array("IDC"), knows2)
    knows2.addConnection(Array("IDB"), knows1)
  }

  /**
   * @deprecated
   * A function to enumerate the current join result.
   * @param out the output collector.
   */
  override def enumeration(out: Collector[String]): Unit = ???

  /**
   * A function to deal with expired elements.
   *
   * @param ctx the current keyed context
   */
  override def expire(ctx: KeyedProcessFunction[Any, Payload, String]#Context): Unit = ???

  /**
   * A function to process new input element.
   *
   * @param value_raw the raw value of current insert element
   * @param ctx       the current keyed context
   * @param out       the output collector, to collect the output stream.
   */
  override def process(value_raw: Payload, ctx: KeyedProcessFunction[Any, Payload, String]#Context, out: Collector[String]): Unit = {
    if (!outSet) {
      outSet = true
      person.setOut(out)
      knows2.setOut(out)
      knows1.setOut(out)
      message.setOut(out)
      middle.setOut(out)
    }
    if (value_raw._1 == "Insert") {
      if (value_raw._2 == "person") person.insert(value_raw._4)
      if (value_raw._2 == "message") message.insert(value_raw._4)
      if (value_raw._2 == "knows2") knows2.insert(value_raw._4)
      if (value_raw._2 == "knows1") knows1.insert(value_raw._4)

    } else {
      if (value_raw._1 == "Delete") {
        if (value_raw._2 == "person") person.delete(value_raw._4)
        if (value_raw._2 == "message") message.delete(value_raw._4)
        if (value_raw._2 == "knows2") knows2.delete(value_raw._4)
        if (value_raw._2 == "knows1") knows1.delete(value_raw._4)
      } else {
        if (value_raw._1 == "Enumerate") {
          val t = middle.fullAttrEnumerate(null)
          for (i<- t) if (i("IDA") != i("IDC")) i
        }
      }
    }
  }

  /**
   * @deprecated
   * A function to store the elements in current time window into the state, for expired.
   * @param value the raw value of current insert element
   * @param ctx   the current keyed context
   */
  override def storeStream(value: Payload, ctx: KeyedProcessFunction[Any, Payload, String]#Context): Unit = ???

  /**
   * @deprecated
   * A function to test whether the new element is already processed or the new element is legal for process.
   * @param value the raw value of current insert element
   * @param ctx   the current keyed context
   * @return a boolean value whether the new element need to be processed.
   */
  override def testExists(value: Payload, ctx: KeyedProcessFunction[Any, Payload, String]#Context): Boolean = ???

  override def close(): Unit = {
    //fileWriter.close()
    super.close()
  }

  class leafRelation(name : String, p_keys : Array[String], next : Relation, override val deltaEnumMode: Int) extends Relation(name, p_keys, next, deltaEnumMode, 0) {


    def enumerate(t : Attributes) : Unit = {
      if (t == null) {
        val keys : Iterable[Attributes] = alive.keys().asScala
        keys.foreach((i : Attributes) => {
          val tempval = alive.get(i)
          tempval.foreach((i : Attributes) => {
            //out.collect(Payload("Output", "Output", 0L, i, 0L))
            System.out.println(i)
          })
        })
      } else {
        val tempval = alive.get(t)
        tempval.foreach((i : Attributes) => {
          System.out.println(i)
        })
      }
    }

  }

  class middleRelation(name : String, p_keys : Array[String], next : Relation, override val deltaEnumMode: Int, numChild : Int) extends Relation(name, p_keys, next, deltaEnumMode, numChild) {



    def enumerate(t : Attributes) : Unit = {
      if (t == null) {
        val keys : Iterable[Attributes] = alive.keys().asScala
        keys.foreach((i : Attributes) => {
          val tempval = alive.get(i)
          tempval.foreach((i : Attributes) => {
            //out.collect(Payload("Output", "Output", 0L, i, 0L))
            System.out.println(i)
          })
        })
      } else {
        val tempval = alive.get(t)
        tempval.foreach((i : Attributes) => {
          System.out.println(i)
        })
      }
    }

    def enumerateD(t : Attributes) : Unit = {
      if (t == null) {
        val keys : Iterable[Attributes] = onhold.keys().asScala
        keys.foreach((i : Attributes) => {
          val tempval = onhold.get(i)
          tempval.foreach((i : (Attributes, Int)) => {
            //out.collect(Payload("Output", "Output", 0L, i, 0L))
            System.out.println(i)
          })
        })
      } else {
        val tempval = onhold.get(t)
        tempval.foreach((i : (Attributes, Int)) => {
          System.out.println(i)
        })
      }
    }

  }
}


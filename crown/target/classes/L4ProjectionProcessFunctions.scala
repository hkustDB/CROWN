import BasedProcessFunctions.BasedProcessFunction
import RelationType.{Attributes, GeneralizedRelation, Payload, Relation}
import org.apache.flink.api.common.typeinfo.{TypeHint, TypeInformation}
import org.apache.flink.streaming.api.functions.KeyedProcessFunction
import org.apache.flink.util.Collector

import scala.collection.JavaConverters._
import scala.collection.mutable

class L4ProjectionProcessFunctions(val deltaEnumMode: Int) extends BasedProcessFunction[Any, Payload, String](0, 0, "L3ProcessFunction") {
  var R2 : middleRelation = null
  var R1 : leafRelation = null
  var R3 : middleRelation = null
  var middle : GeneralizedRelation = null
  var R4 : leafRelation = null
  var outSet : Boolean = false
  /**
   * A function to initial the state as Flink required.
   */
  override def initstate(): Unit = {
    val attributeDescriptor = TypeInformation.of(new TypeHint[Attributes]() {})
    val setAttributeDescriptor = TypeInformation.of(new TypeHint[mutable.HashSet[Attributes]]() {})
    val mapAttributeDescriptor = TypeInformation.of(new TypeHint[mutable.HashMap[Attributes, Int]](){} )
    middle = new GeneralizedRelation("[c]", Array("C"), null, deltaEnumMode, 2) {}
    R2 =  new middleRelation("R2", Array("C"), middle, deltaEnumMode, 1)
    R3 = new middleRelation("R3", Array("C"), middle, deltaEnumMode, 1)
    R1 = new leafRelation("R1", Array("B"), R2, deltaEnumMode)
    R4 =  new leafRelation("R4", Array("D"), R3, deltaEnumMode)

    R3.initState(getRuntimeContext, attributeDescriptor, setAttributeDescriptor, mapAttributeDescriptor)
    R1.initState(getRuntimeContext, attributeDescriptor, setAttributeDescriptor)
    R2.initState(getRuntimeContext, attributeDescriptor, setAttributeDescriptor, mapAttributeDescriptor)
    R4.initState(getRuntimeContext, attributeDescriptor, setAttributeDescriptor)
    middle.initState(getRuntimeContext, attributeDescriptor, setAttributeDescriptor, mapAttributeDescriptor)
    R2.addConnection(Array("B"), R1)
    R3.addConnection(Array("D"), R4)
    middle.addConnection(Array("C"), R2)
    middle.addConnection(Array("C"), R3)
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
      R1.setOut(out)
      R3.setOut(out)
      middle.setOut(out)
      R4.setOut(out)
      R2.setOut(out)
    }
    if (value_raw._1 == "Insert") {
      if (value_raw._2 == "R1") R1.insert(value_raw._4)
      if (value_raw._2 == "R2") R2.insert(value_raw._4)
      if (value_raw._2 == "R3") R3.insert(value_raw._4)
      if (value_raw._2 == "R4") R4.insert(value_raw._4)
    } else {
      if (value_raw._1 == "Delete") {
        if (value_raw._2 == "R1") R1.delete(value_raw._4)
        if (value_raw._2 == "R2") R2.delete(value_raw._4)
        if (value_raw._2 == "R3") R3.delete(value_raw._4)
        if (value_raw._2 == "R4") R4.delete(value_raw._4)
      } else {
        if (value_raw._1 == "Enumerate") {
          val t = middle.fullAttrEnumerate(null)
          for (i<- t) i
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

  class leafRelation(name : String, p_keys : Array[String], next : Relation, override val deltaEnumMode: Int) extends Relation(name, p_keys, next, deltaEnumMode, 0, false) {


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

  class middleRelation(name : String, p_keys : Array[String], next : Relation, override val deltaEnumMode: Int, numChild : Int) extends Relation(name, p_keys, next, deltaEnumMode, numChild, true) {



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


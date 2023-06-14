import BasedProcessFunctions.BasedProcessFunction
import RelationType.{AnnotatedRelation, Attributes, GeneralizedRelation, Payload, Relation}
import org.apache.flink.api.common.typeinfo.{TypeHint, TypeInformation}
import org.apache.flink.streaming.api.functions.KeyedProcessFunction
import org.apache.flink.util.Collector

import scala.collection.JavaConverters._
import scala.collection.mutable

class SNBQ4ProcessFunctions(val deltaEnumMode: Int) extends BasedProcessFunction[Any, Payload, String](0, 0, "L3ProcessFunction") {
  var knows : leafRelation = null
  var Message : middleRelation = null
  var middle : GeneralizedRelation = null
  var messageTag : middleARelation = null
  var tag : middleRelation = null
  var outSet : Boolean = false
  /**
   * A function to initial the state as Flink required.
   */
  override def initstate(): Unit = {
    val attributeDescriptor = TypeInformation.of(new TypeHint[Attributes]() {})
    val setAttributeDescriptor = TypeInformation.of(new TypeHint[mutable.HashSet[Attributes]]() {})
    val mapAttributeDescriptor = TypeInformation.of(new TypeHint[mutable.HashMap[Attributes, Int]](){} )
    middle = new GeneralizedRelation("[TagID]", Array("TagID"), null, deltaEnumMode, 1) {}
    tag = new middleRelation("Tag", Array("TagID"), middle, deltaEnumMode, 1, true)
    messageTag =  new middleARelation("messageTag", Array("TagID"), tag, deltaEnumMode, 1)
    Message = new middleRelation("message", Array("MessageID"), messageTag, deltaEnumMode, 1, false)
    knows = new leafRelation("knows", Array("IDB"), Message, deltaEnumMode, false)

    tag.initState(getRuntimeContext, attributeDescriptor, setAttributeDescriptor, mapAttributeDescriptor)
    Message.initState(getRuntimeContext, attributeDescriptor, setAttributeDescriptor, mapAttributeDescriptor)
    knows.initState(getRuntimeContext, attributeDescriptor, setAttributeDescriptor)
    messageTag.initState(getRuntimeContext, attributeDescriptor, setAttributeDescriptor, mapAttributeDescriptor)
    middle.initState(getRuntimeContext, attributeDescriptor, setAttributeDescriptor, mapAttributeDescriptor)
    Message.addConnection(Array("IDB"), knows)
    messageTag.addConnection(Array("MessageID"), Message)
    tag.addConnection(Array("TagID"), messageTag)
    middle.addConnection(Array("TagID"), tag)
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
      knows.setOut(out)
      Message.setOut(out)
      middle.setOut(out)
      messageTag.setOut(out)
      tag.setOut(out)
    }
    if (value_raw._1 == "Insert") {
      if (value_raw._2 == "knows") knows.insert(value_raw._4)
      if (value_raw._2 == "message") Message.insert(value_raw._4)
      if (value_raw._2 == "messageTag") messageTag.insert(value_raw._4)
      if (value_raw._2 == "tag") tag.insert(value_raw._4)
    } else {
      if (value_raw._1 == "Delete") {
        if (value_raw._2 == "knows") knows.delete(value_raw._4)
        if (value_raw._2 == "message") Message.delete(value_raw._4)
        if (value_raw._2 == "messageTag") messageTag.delete(value_raw._4)
        if (value_raw._2 == "tag") tag.insert(value_raw._4)
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

  class leafRelation(name : String, p_keys : Array[String], next : Relation, override val deltaEnumMode: Int, isOutput :Boolean)
    extends Relation(name, p_keys, next, deltaEnumMode, 0, isOutput) {


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

  class middleARelation(name : String, p_keys : Array[String], next : Relation, override val deltaEnumMode: Int, numChild : Int)
    extends AnnotatedRelation(name, p_keys, next, deltaEnumMode, numChild) {


    def enumerate(t: Attributes): Unit = {
      if (t == null) {
        val keys: Iterable[Attributes] = alive.keys().asScala
        keys.foreach((i: Attributes) => {
          val tempval = alive.get(i)
          tempval.foreach((i: Attributes) => {
            //out.collect(Payload("Output", "Output", 0L, i, 0L))
            System.out.println(i)
          })
        })
      } else {
        val tempval = alive.get(t)
        tempval.foreach((i: Attributes) => {
          System.out.println(i)
        })
      }
    }

    def enumerateD(t: Attributes): Unit = {
      if (t == null) {
        val keys: Iterable[Attributes] = onhold.keys().asScala
        keys.foreach((i: Attributes) => {
          val tempval = onhold.get(i)
          tempval.foreach((i: (Attributes, Int)) => {
            //out.collect(Payload("Output", "Output", 0L, i, 0L))
            System.out.println(i)
          })
        })
      } else {
        val tempval = onhold.get(t)
        tempval.foreach((i: (Attributes, Int)) => {
          System.out.println(i)
        })
      }
    }
  }



  class middleRelation(name : String, p_keys : Array[String], next : Relation, override val deltaEnumMode: Int, numChild : Int, isOutput : Boolean)
    extends Relation(name, p_keys, next, deltaEnumMode, numChild, isOutput) {



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


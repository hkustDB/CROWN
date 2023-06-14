import scala.collection.JavaConverters._
import BasedProcessFunctions.BasedProcessFunction
import RelationType.{Attributes, Payload, Relation}
import org.apache.flink.api.common.typeinfo.{BasicTypeInfo, TypeHint, TypeInformation}
import org.apache.flink.streaming.api.functions.KeyedProcessFunction
import org.apache.flink.util.Collector

import scala.collection.mutable

class DumbbellFlinkTriangleProcessFunction(val deltaEnumMode: Int) extends BasedProcessFunction[Any, Payload, String](0, 0, "L3ProcessFunction") {
    //var fileWriter : FileWriter = null
    var middle : middleRelation = null
    var left : leafRelation = null
    var right : leafRelation = null
    var outSet : Boolean = false
    /**
     * A function to initial the state as Flink required.
     */
    override def initstate(): Unit = {
        val attributeDescriptor = TypeInformation.of(new TypeHint[Attributes]() {})
        val setAttributeDescriptor = TypeInformation.of(new TypeHint[mutable.HashSet[Attributes]]() {})
        val mapAttributeDescriptor = TypeInformation.of(new TypeHint[mutable.HashMap[Attributes, Int]](){} )

        middle =  new middleRelation("middle", Array("C", "D"), null, deltaEnumMode)
        left = new leafRelation("left", Array("C"), middle, deltaEnumMode)
        right =  new leafRelation("right", Array("D"), middle, deltaEnumMode)
        left.initState(getRuntimeContext, attributeDescriptor, setAttributeDescriptor)
        middle.initState(getRuntimeContext, attributeDescriptor, setAttributeDescriptor, mapAttributeDescriptor)
        right.initState(getRuntimeContext, attributeDescriptor, setAttributeDescriptor)
        middle.addConnection(Array("C"), left)
        middle.addConnection(Array("D"), right)
    }

    override def onTimer(timestamp: Long, ctx: KeyedProcessFunction[Any, Payload, String]#OnTimerContext, out: Collector[String]): Unit = {
        // should be invoked only when we reach the end of input stream
        val t = middle.fullAttrEnumerate(null)
        for (i<- t) out.collect(i.toString)
    }

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
            left.setOut(out)
            right.setOut(out)
            middle.setOut(out)
            ctx.timerService().registerEventTimeTimer(Long.MaxValue - 10000L)
        }
        if (value_raw._1 == "Insert") {
            if (value_raw._2 == "left") left.insert(value_raw._4)
            if (value_raw._2 == "middle") middle.insert(value_raw._4)
            if (value_raw._2 == "right") right.insert(value_raw._4)
        } else if (value_raw._1 == "Delete") {
                if (value_raw._2 == "left") left.delete(value_raw._4)
                if (value_raw._2 == "middle") middle.delete(value_raw._4)
                if (value_raw._2 == "right") right.delete(value_raw._4)
        }
    }

    override def close(): Unit = {
        //fileWriter.close()
        super.close()
    }

    class leafRelation(name : String, p_keys : Array[String], next : Relation, override val deltaEnumMode: Int) extends Relation(name, p_keys, next, deltaEnumMode,0, isOutput = false){}

    class middleRelation(name : String, p_keys : Array[String], next : Relation, override val deltaEnumMode: Int) extends Relation(name, p_keys, next, deltaEnumMode, 2) {}

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
}


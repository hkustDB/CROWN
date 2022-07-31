import BasedProcessFunctions.BasedProcessFunction
import RelationType.{Attributes, GeneralizedRelation, Payload, Relation, Triangle}
import org.apache.flink.api.common.typeinfo.{TypeHint, TypeInformation}
import org.apache.flink.streaming.api.functions.KeyedProcessFunction
import org.apache.flink.util.Collector

import scala.collection.mutable

class DumbbellCrownTriangleProcessFunction(val deltaEnumMode: Int) extends BasedProcessFunction[Any, Payload, String](0, 0, "L3ProcessFunction") {
    var leftTriangle: Triangle = null
    var leftRelation: GeneralizedRelation = null
    var rightTriangle: Triangle = null
    var rightRelation: GeneralizedRelation = null
    var root: Relation = null

    var isTimerSet = false

    override def onTimer(timestamp: Long, ctx: KeyedProcessFunction[Any, Payload, String]#OnTimerContext, out: Collector[String]): Unit = {
        // full enumeration at the end
        val t = root.fullAttrEnumerate(null)
        for (i <- t) out.collect(i.toString)
    }

    /**
     * A function to initial the state as Flink required.
     */
    override def initstate(): Unit = {
        val attributeDescriptor = TypeInformation.of(new TypeHint[Attributes]() {})
        val setAttributeDescriptor = TypeInformation.of(new TypeHint[mutable.HashSet[Attributes]]() {})
        val mapAttributeDescriptor = TypeInformation.of(new TypeHint[mutable.HashMap[Attributes, Int]](){} )

        root = new Relation("middle", Array("C", "D"), null, deltaEnumMode, 2) {}
        leftRelation = new GeneralizedRelation("left", Array("C"), root, deltaEnumMode, 1) {}
        leftTriangle = new Triangle("LT", Array("A","B","C"), Array("A","B","C"), leftRelation, deltaEnumMode)
        rightRelation = new GeneralizedRelation("right", Array("D"), root, deltaEnumMode, 1) {}
        rightTriangle = new Triangle("RT", Array("D","E","F"), Array("D","E","F"), rightRelation, deltaEnumMode)

        root.initState(getRuntimeContext, attributeDescriptor, setAttributeDescriptor, mapAttributeDescriptor)
        leftRelation.initState(getRuntimeContext, attributeDescriptor, setAttributeDescriptor, mapAttributeDescriptor)
        leftTriangle.initState(getRuntimeContext, attributeDescriptor, setAttributeDescriptor, mapAttributeDescriptor)

        rightRelation.initState(getRuntimeContext, attributeDescriptor, setAttributeDescriptor, mapAttributeDescriptor)
        rightTriangle.initState(getRuntimeContext, attributeDescriptor, setAttributeDescriptor, mapAttributeDescriptor)

        root.addConnection(Array("C"), leftRelation)
        root.addConnection(Array("D"), rightRelation)
        leftRelation.addConnection(Array("A","B","C"), leftTriangle)
        rightRelation.addConnection(Array("D","E","F"), rightTriangle)
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
        if (!isTimerSet) {
            root.setOut(out)
            leftRelation.setOut(out)
            leftTriangle.setOut(out)
            rightRelation.setOut(out)
            rightTriangle.setOut(out)
            ctx.timerService().registerEventTimeTimer(Long.MaxValue - 1000L)
        }

        value_raw._2 match {
            case "middle" =>
                dispatch(value_raw, root, out)
            case "left" =>
                dispatch(value_raw, leftTriangle, out)
            case "right" =>
                dispatch(value_raw, rightTriangle, out)
        }
    }

    def dispatch(payload: Payload, relation: Relation, out: Collector[String]): Unit = {
        payload._1 match {
            case "Insert" =>
                relation.insert(payload._4)
            case "Delete" =>
                relation.delete(payload._4)
            case "Enumerate" =>
                assert(relation == root)
                val t = root.fullAttrEnumerate(null)
                for (i <- t) i
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
}

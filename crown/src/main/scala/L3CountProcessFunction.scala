import BasedProcessFunctions.BasedProcessFunction
import RelationType.{AnnotatedRelation, Attributes, GeneralizedRelation, Payload}
import org.apache.flink.api.common.typeinfo.{TypeHint, TypeInformation}
import org.apache.flink.streaming.api.functions.KeyedProcessFunction
import org.apache.flink.util.Collector

import scala.collection.mutable

class L3CountProcessFunction(val deltaEnumMode: Int) extends BasedProcessFunction[Any, Payload, String](0, 0, "L3CountProcessFunction") {
    var root: GeneralizedRelation = null
    var r1: AnnotatedRelation = null
    var r2: AnnotatedRelation = null
    var r3: AnnotatedRelation = null
    var outSet : Boolean = false

    override def initstate(): Unit = {
        val attributeDescriptor = TypeInformation.of(new TypeHint[Attributes]() {})
        val setAttributeDescriptor = TypeInformation.of(new TypeHint[mutable.HashSet[Attributes]]() {})
        val mapAttributeDescriptor = TypeInformation.of(new TypeHint[mutable.HashMap[Attributes, Int]]() {})


        root = new GeneralizedRelation("[E]", Array("E"), null, deltaEnumMode, 1) {}
        r2 = new AnnotatedRelation("R2", Array("E"), root, deltaEnumMode, 2) {}
        r1 = new AnnotatedRelation("R1", Array("B"), r2, deltaEnumMode, 0) {}
        r3 = new AnnotatedRelation("R3", Array("C"), r2, deltaEnumMode, 0) {}

        root.initState(getRuntimeContext, attributeDescriptor, setAttributeDescriptor, mapAttributeDescriptor)
        r1.initState(getRuntimeContext, attributeDescriptor, setAttributeDescriptor)
        r2.initState(getRuntimeContext, attributeDescriptor, setAttributeDescriptor, mapAttributeDescriptor)
        r3.initState(getRuntimeContext, attributeDescriptor, setAttributeDescriptor)

        r2.addConnection(Array("B"), r1)
        r2.addConnection(Array("C"), r3)
        root.addConnection(Array("E"), r2)
    }

    override def enumeration(out: Collector[String]): Unit = ???
    override def expire(ctx: KeyedProcessFunction[Any, Payload, String]#Context): Unit = ???

    override def process(value_raw: Payload, ctx: KeyedProcessFunction[Any, Payload, String]#Context, out: Collector[String]): Unit = {
        if (!outSet) {
            outSet = true
            r1.setOut(out)
            r2.setOut(out)
            r3.setOut(out)
            root.setOut(out)
        }
        if (value_raw._1 == "Insert") {
            if (value_raw._2 == "R1") r1.insert(value_raw._4)
            if (value_raw._2 == "R2") r2.insert(value_raw._4)
            if (value_raw._2 == "R3")
                r3.insert(value_raw._4)
        } else {
            if (value_raw._1 == "Delete") {
                if (value_raw._2 == "R1") r1.delete(value_raw._4)
                if (value_raw._2 == "R2") r2.delete(value_raw._4)
                if (value_raw._2 == "R3") r3.delete(value_raw._4)
            } else {
                if (value_raw._1 == "Enumerate") {
                    val t = root.fullAttrEnumerate(null)
                    for (i <- t) {
                        println(i)
                    }
                }
            }
        }
    }

    override def storeStream(value: Payload, ctx: KeyedProcessFunction[Any, Payload, String]#Context): Unit = ???
    override def testExists(value: Payload, ctx: KeyedProcessFunction[Any, Payload, String]#Context): Boolean = ???
}

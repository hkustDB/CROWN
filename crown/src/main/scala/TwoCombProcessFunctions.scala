import BasedProcessFunctions.BasedProcessFunction
import RelationType.{Attributes, Payload, Relation}
import org.apache.flink.api.common.typeinfo.{TypeHint, TypeInformation}
import org.apache.flink.streaming.api.functions.KeyedProcessFunction
import org.apache.flink.util.Collector

import scala.collection.JavaConverters._
import scala.collection.mutable

class TwoCombProcessFunctions(val deltaEnumMode: Int) extends BasedProcessFunction[Any, Payload, String](0, 0, "L3ProcessFunction") {
    //var fileWriter : FileWriter = null
    var relationBC : middleRelation = null
    var relationAB : Relation = null
    var relationCD : Relation = null
    var relationA: leafRelation = null
    var relationD: leafRelation = null
    var outSet : Boolean = false
    /**
     * A function to initial the state as Flink required.
     */
    override def initstate(): Unit = {
        val attributeDescriptor = TypeInformation.of(new TypeHint[Attributes]() {})
        val setAttributeDescriptor = TypeInformation.of(new TypeHint[mutable.HashSet[Attributes]]() {})
        val mapAttributeDescriptor = TypeInformation.of(new TypeHint[mutable.HashMap[Attributes, Int]](){} )

        relationBC =  new middleRelation("G2", Array("B", "C"), null, deltaEnumMode)
        relationAB = new Relation("G1", Array("B"), relationBC, deltaEnumMode, 1) {}
        relationCD =  new Relation("G3", Array("C"), relationBC, deltaEnumMode, 1) {}
        relationA = new leafRelation("V1", Array("A"), relationAB, deltaEnumMode)
        relationD = new leafRelation("V2", Array("D"), relationCD, deltaEnumMode)
        relationBC.initState(getRuntimeContext, attributeDescriptor, setAttributeDescriptor, mapAttributeDescriptor)
        relationAB.initState(getRuntimeContext, attributeDescriptor, setAttributeDescriptor, mapAttributeDescriptor)
        relationCD.initState(getRuntimeContext, attributeDescriptor, setAttributeDescriptor, mapAttributeDescriptor)
        relationA.initState(getRuntimeContext, attributeDescriptor, setAttributeDescriptor)
        relationD.initState(getRuntimeContext, attributeDescriptor, setAttributeDescriptor)
        relationBC.addConnection(Array("B"), relationAB)
        relationBC.addConnection(Array("C"), relationCD)
        relationAB.addConnection(Array("A"), relationA)
        relationCD.addConnection(Array("D"), relationD)
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
            relationBC.setOut(out)
            relationAB.setOut(out)
            relationCD.setOut(out)
            relationA.setOut(out)
            relationD.setOut(out)
        }
        if (value_raw._1 == "Insert") {
            if (value_raw._2 == "G1") relationAB.insert(value_raw._4)
            if (value_raw._2 == "G2") relationBC.insert(value_raw._4)
            if (value_raw._2 == "G3") relationCD.insert(value_raw._4)
            if (value_raw._2 == "V1") relationA.insert(value_raw._4)
            if (value_raw._2 == "V2") relationD.insert(value_raw._4)
        } else {
            if (value_raw._1 == "Delete") {
                if (value_raw._2 == "G1") relationAB.delete(value_raw._4)
                if (value_raw._2 == "G2") relationBC.delete(value_raw._4)
                if (value_raw._2 == "G3") relationCD.delete(value_raw._4)
                if (value_raw._2 == "V1") relationA.delete(value_raw._4)
                if (value_raw._2 == "V2") relationD.delete(value_raw._4)
            } else {
                if (value_raw._1 == "Enumerate") {
                    val t = relationBC.fullAttrEnumerate(null)
                    println("enum begin")
                    for (i<- t) i
                    println("end enum")
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

    class leafRelation(name : String, p_keys : Array[String], next : Relation, override val deltaEnumMode: Int) extends Relation(name, p_keys, next, deltaEnumMode,0) {


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

    class middleRelation(name : String, p_keys : Array[String], next : Relation, override val deltaEnumMode: Int) extends Relation(name, p_keys, next, deltaEnumMode, 2) {



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

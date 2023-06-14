package RelationType

import org.apache.flink.api.common.functions.RuntimeContext
import org.apache.flink.api.common.state.{MapState, MapStateDescriptor, ValueState, ValueStateDescriptor}
import org.apache.flink.api.common.typeinfo.{BasicTypeInfo, TypeInformation}

import java.io.FileWriter
import scala.collection.mutable

/**
 * This is a implementation of triangle join over CROWN framework.
 *
 * let a = INPUT_KEY(0), b = INPUT_KEY(1), c = INPUT_KEY(2)
 * The class would evaluate
 * SELECT [JOIN_KEY]
 * from graph g1, graph g2, graph g3
 * where g1.a = g3.a and g1.b = g2.b and g2.c = g3.c
 *
 * The inputted edge must have attribute set [INPUT_KEY(0), INPUT_KEY(1)], [INPUT_KEY(1), INPUT_KEY(2)], or [INPUT_KEY(2), INPUT_KEY(0)]
 */
class Triangle(name : String, inputKey: Array[String], joinkey : Array[String], nextRelation : Relation, override val deltaEnumMode: Int,
              )
  extends Bag(name, joinkey, nextRelation, deltaEnumMode) {
  val keyA = inputKey(0)
  val keyB = inputKey(1)
  val keyC = inputKey(2)

  var graphAB : MapState[Attributes, Attributes] = _
  var graphBC : MapState[Attributes, Attributes] = _
  var graphCA : MapState[Attributes, Attributes] = _
  var graphA : MapState[Attributes, mutable.HashSet[Attributes]] = _
  var graphB : MapState[Attributes, mutable.HashSet[Attributes]] = _
  var graphC : MapState[Attributes, mutable.HashSet[Attributes]] = _
  var deltaList : mutable.HashSet[Attributes] = new mutable.HashSet()

  override def initState(runtimeContext: RuntimeContext,
                         attributesDescriptor: TypeInformation[Attributes],
                         setAttributesDescriptor: TypeInformation[mutable.HashSet[Attributes]],
                         mapAttributesDescriptor: TypeInformation[mutable.HashMap[Attributes, Int]]): Unit = {
    val aliveDescriptor = new MapStateDescriptor[Attributes, mutable.HashSet[Attributes]](name+"alive", attributesDescriptor, setAttributesDescriptor)
    val keyCountDescriptor = new MapStateDescriptor[Attributes, Int](name+"keyCount", attributesDescriptor, BasicTypeInfo.INT_TYPE_INFO.asInstanceOf[TypeInformation[Int]])

    attributeDescriptor = attributesDescriptor
    setAttributeDescriptor = setAttributesDescriptor
    val graphABDescriptor = new MapStateDescriptor[Attributes, Attributes](name+"graphAB", attributesDescriptor, attributesDescriptor)
    val graphBCDescriptor = new MapStateDescriptor[Attributes, Attributes](name+"graphBC", attributesDescriptor, attributesDescriptor)
    val graphCADescriptor = new MapStateDescriptor[Attributes, Attributes](name+"graphCA", attributesDescriptor, attributesDescriptor)
    val graphADescriptor = new MapStateDescriptor[Attributes, mutable.HashSet[Attributes]](name+"graphA", attributesDescriptor, setAttributesDescriptor)
    val graphBDescriptor = new MapStateDescriptor[Attributes, mutable.HashSet[Attributes]](name+"graphB", attributesDescriptor, setAttributesDescriptor)
    val graphCDescriptor = new MapStateDescriptor[Attributes, mutable.HashSet[Attributes]](name+"graphC", attributesDescriptor, setAttributesDescriptor)
    runtime = runtimeContext


    alive = runtimeContext.getMapState(aliveDescriptor)
    keyCount = runtimeContext.getMapState(keyCountDescriptor)
    graphA = runtimeContext.getMapState(graphADescriptor)
    graphB = runtimeContext.getMapState(graphBDescriptor)
    graphC = runtimeContext.getMapState(graphCDescriptor)
    graphAB = runtimeContext.getMapState(graphABDescriptor)
    graphBC = runtimeContext.getMapState(graphBCDescriptor)
    graphCA = runtimeContext.getMapState(graphCADescriptor)
  }

  override def addConnection(keys: Array[String], relation: Relation): Unit = {
    throw new Exception("Add connection to non-child node")
  }

  override protected def insertKeyMap(tuple : Attributes) : Unit = {
    throw new Exception("insert key map to non-child node")
  }

  override protected def deleteKeyMap(tuple: Attributes): Unit = {
    throw new Exception("Delete key map to non-child node")
  }

  override protected def changeToAliveConnection(tuple: Attributes): Unit = {
    throw new Exception("Change Connection to non-child node")
  }

  override protected def changeToOnHoldConnection(tuple: Attributes): Unit = {
    throw new Exception("Change Connection to non-child node")
  }

  private def insertIntoIndex(key : Array[String],
                          valueIndex : MapState[Attributes, Attributes],
                          keyIndex : MapState[Attributes, mutable.HashSet[Attributes]],
                          tuple : Attributes) : Unit = {
    if (valueIndex.contains(tuple)) throw new Exception("Edge already exists! " + tuple)
    valueIndex.put(tuple, tuple)
    val projectKey = tuple.projection(key)
    addElementToIndex(projectKey, tuple, keyIndex)
  }

  private def deleteFromIndex(key : Array[String],
                              valueIndex : MapState[Attributes, Attributes],
                              keyIndex : MapState[Attributes, mutable.HashSet[Attributes]],
                              tuple : Attributes) : Unit = {
    if (!valueIndex.contains(tuple)) throw new Exception("Edge does not exists! " + tuple)
    valueIndex.remove(tuple)
    val projectKey = tuple.projection(key)
    deleteElementFromIndex(projectKey, tuple, keyIndex)
  }

  private def calculateDelta(tuple : Attributes,
                             valueIndex : MapState[Attributes, Attributes],
                             key : Array[String],
                             keyIndex : MapState[Attributes, mutable.HashSet[Attributes]]) : Unit = {
    deltaList.clear()
    val projectKey = tuple.projection(key)
    val connectList = keyIndex.get(projectKey)

    if (!valueIndex.isEmpty && connectList != null) {
      val valueKey = valueIndex.keys().iterator().next().keys
      for (i <- connectList) {
        val t = i.join(tuple)
        if (valueIndex.contains(t.projection(valueKey))) {
          deltaList.add(t)
        }
      }
    }
  }

  override def insert(tuple : Attributes) : Unit = {
    if (tuple.containsKey(keyA) && tuple.containsKey(keyB)) {
      insertIntoIndex(Array(keyA), graphAB, graphA, tuple)
      calculateDelta(tuple, graphCA, Array(keyB), graphB)
    } else {
      if (tuple.containsKey(keyB) && tuple.containsKey(keyC)) {
        insertIntoIndex(Array(keyB), graphBC, graphB, tuple)
        calculateDelta(tuple, graphAB, Array(keyC), graphC)
      } else {
        if (tuple.containsKey(keyC) && tuple.containsKey(keyA)) {
          insertIntoIndex(Array(keyC), graphCA, graphC, tuple)
          calculateDelta(tuple, graphBC, Array(keyA), graphA)
        } else {
          throw new Exception("The schema does not follow the requirement")
        }
      }
    }
    // deltaList stores the delta result after the update.
    for (i<-deltaList) {
      aliveAdd(i)
    }
  }

  override def delete(tuple : Attributes) : Unit = {
    if (tuple.containsKey(keyA) && tuple.containsKey(keyB)) {
      deleteFromIndex(Array(keyA), graphAB, graphA, tuple)
      calculateDelta(tuple, graphCA, Array(keyB), graphB)
    } else {
      if (tuple.containsKey(keyB) && tuple.containsKey(keyC)) {
        deleteFromIndex(Array(keyB), graphBC, graphB, tuple)
        calculateDelta(tuple, graphAB, Array(keyC), graphC)
      } else {
        if (tuple.containsKey(keyC) && tuple.containsKey(keyA)) {
          deleteFromIndex(Array(keyC), graphCA, graphC, tuple)
          calculateDelta(tuple, graphBC, Array(keyA), graphA)
        } else {
          throw new Exception("The schema does not follow the requirement")
        }
      }
    }
    // deltaList stores the delta result after the update.
    for (i<-deltaList) {
      aliveDelete(i)
    }
  }

  override def fullAttrEnumerate(keys: Attributes, operation: String): Iterator[Attributes] = new fullAttrTriangleEnumerator(keys, operation)

  class fullAttrTriangleEnumerator(tuple : Attributes, operation : String = "Insert") extends Iterator[Attributes] {
    var iterator1: Iterator[Attributes] = null
    var value: Attributes = null
    var n: Int = 0
    var init: Boolean = false

    def open: Unit = {
      init = true
      if (tuple.containsKey(keyA) && tuple.containsKey(keyB) && tuple.containsKey(keyC)) {
        value = tuple
        n = 0
      } else {
        iterator1 = alive.get(tuple).toIterator
      }
    }

    override def hasNext: Boolean = {
      if (!init) open
      if (iterator1 != null) iterator1.hasNext
      else n == 0
    }

    override def next(): Attributes = {
      if (!init) open
      if (hasNext) {
        if (iterator1 != null) return iterator1.next
        else {
          n = 1
          return value
        }
      } else {
        throw new Exception("Iterator call next() for empty list!")
      }
    }
  }

  // TODO: use this method to output a single tuple in delta enumeration.
//  def outputSingleResult(attr : Attributes, operator : String, outputPath : String = ""): Unit = {
//    this.deltaEnumMode match {
//      case 0 => attr
//      case 1 => {
//        val fw = new FileWriter(outputPath, true)
//        try {
//          fw.write(operator + " " + attr + "\n" /* your stuff */)
//        }
//        finally fw.close()
//      }
//      case 2 => println(operator + " " + attr)
//      case 3 => out.collect(operator + " " + attr)
//      case 4 =>
//      case 5 => out.collect(operator + " " + attr + " lat: " + (System.currentTimeMillis()-time.value()).toString)
//      case _ => throw new NoSuchMethodException("Output Mode " + deltaEnumMode + " is not supported, please check your code")
//    }
//  }
}

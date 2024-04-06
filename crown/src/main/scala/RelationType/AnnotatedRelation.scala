package RelationType
import org.apache.flink.api.common.functions.RuntimeContext
import org.apache.flink.api.common.state.{MapState, MapStateDescriptor}
import org.apache.flink.api.common.typeinfo.{BasicTypeInfo, TypeInformation}

import scala.collection.mutable

/**
 *
 * The annotation relation will be non-outputed relation.
 */
abstract class AnnotatedRelation(name : String, joinkey : Array[String], nextRelation : Relation, override val deltaEnumMode: Int, numChild : Int = 0)
 extends Relation(name, joinkey, nextRelation, deltaEnumMode, numChild, false) {
  var wp: MapState[Attributes, Double] = _

  /***
   * Index: alive/onhold using join key as key.  onhold also contains s(t) for each t;
   *        connection for each join child c, where _3 contains all onhold tuples, _4 contains all alive tuples, without
   *          s(t)
   * Insert a tuple to index:
   *    1. first, determine whether the tuple is alive or not;
   *    2. if it is alive, add it to alive for alive set, for alive index and all connection
   *    3. else, add it to onhold set, for onhold index and all connection
   *    4. Trigger further updates if alive.
   *
   * Delete a tuple from index:
   *    1. first, determine whether the tuple is alive or not;
   *    2. if it is alive, remove it from alive set, for alive index and all connection
   *    3. else, remove it from onhold set, for onhold index and all connection
   *    4. Trigger further updates if it was alive.
   *
   * Update a key to alive:
   *    1. first, determine which relation based on the relation;
   *    2. use onhold index to add s[t] for all valid t with the key
   *    3. if s[t] == numChild, delete t from onhold set and move t to alive set, also, all connections need to be
   *        updated.   (Should put them in a buffer first)
   *    4. Trigger further updates if applicable.
   *
   * Update a key to onhold:
   *    1. first, use onhold index to update s[t] by s[t] - 1;
   *    2. use alive index to move these tuples to onhold set
   *    3. Trigger further updates if applicable
   *    4. Remove all tuples in the local alive index.
   */

  override protected def aliveAdd(tuple : Attributes) : Unit = {
    tuple.annotation = getAnnotation(tuple)
    val projectB = tuple.projection(joinkey)
    if (wp.contains(projectB)) {
      wp.put(projectB, wp.get(projectB) + tuple.annotation)
    } else {
      wp.put(projectB, tuple.annotation)
    }

    if (alive.contains(projectB)) {
      if (!keyCount.contains(projectB))
        throw new Exception("ERROR! Element not found!")
      val tempCount = keyCount.get(projectB)
      keyCount.put(projectB, tempCount+1)
      nextRelation.updateAnnotation(projectB, this)
    } else {
      if (keyCount.contains(projectB))
        throw new Exception("ERROR! Should be Zero")
      else keyCount.put(projectB, 1)
    }
    addElementToIndex(projectB, tuple, alive)
    triggerUpdate(tuple, "Insert")
  }

  override protected def aliveDelete(tuple : Attributes) : Unit = {
    val projectB = tuple.projection(joinkey)
    tuple.annotation = getAnnotation(tuple)
    wp.put(projectB, wp.get(projectB) - tuple.annotation)
    nextRelation.updateAnnotation(projectB, this)

    if (!keyCount.contains(projectB))
      throw new Exception("ERROR! Element not found!")
    else {
      val tempCount = keyCount.get(projectB)
      if (tempCount == 1) {
        keyCount.remove(projectB)
        wp.remove(projectB)
      } else {
        keyCount.put(projectB, tempCount-1)
      }
      triggerUpdate(tuple, "Delete")
      deleteElementFromIndex(projectB, tuple, alive)
    }

  }

  override def toString: String = {
    "AnnotatedRelation " + name
  }

  override def initState(runtimeContext: RuntimeContext, attributesDescriptor: TypeInformation[Attributes], setAttributesDescriptor: TypeInformation[mutable.HashSet[Attributes]], mapAttributesDescriptor: TypeInformation[mutable.HashMap[Attributes, Int]]): Unit = {
    super.initState(runtimeContext, attributesDescriptor, setAttributesDescriptor, mapAttributesDescriptor)

    val wpDescriptor = new MapStateDescriptor[Attributes, Double](name + "wp", attributesDescriptor, BasicTypeInfo.DOUBLE_TYPE_INFO.asInstanceOf[TypeInformation[Double]])
    wp = runtimeContext.getMapState(wpDescriptor)
  }

  override def getWpByKey(key: Attributes): Double = {
    wp.get(key)
  }

  override def updateWpByKey(key: Attributes, delta: Double): Unit = {
    wp.put(key, wp.get(key) + delta)
  }
}
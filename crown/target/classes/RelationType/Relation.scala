package RelationType

import java.io.FileWriter
import org.apache.flink.api.common.functions.RuntimeContext
import org.apache.flink.api.common.state.{MapState, MapStateDescriptor, ValueState}
import org.apache.flink.api.common.typeinfo.{BasicTypeInfo, TypeInformation}
import org.apache.flink.util.Collector

import scala.collection.JavaConverters.iterableAsScalaIterableConverter
import scala.collection.mutable
import scala.collection.mutable.ArrayBuffer

abstract class Relation(name : String, joinkey : Array[String], nextRelation : Relation, val deltaEnumMode: Int, numChild : Int = 0, val isOutput : Boolean = true) {

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

  var alive : MapState[Attributes, mutable.HashSet[Attributes]] = _
  var onhold : MapState[Attributes, mutable.HashMap[Attributes, Int]] = _
  var keyCount : MapState[Attributes, Int] = _
  var time : ValueState[Long] = _
  type TupleConnection = (Relation,
      Array[String],
      MapState[Attributes, mutable.HashSet[Attributes]],
      MapState[Attributes, mutable.HashSet[Attributes]],
      MapState[Attributes, mutable.HashSet[Attributes]])
  var connection : ArrayBuffer[TupleConnection] = new ArrayBuffer()
  var cnt = 0
  var attributeDescriptor : TypeInformation[Attributes] = _
  var setAttributeDescriptor : TypeInformation[mutable.HashSet[Attributes]] = _
  var runtime : RuntimeContext = _
  var out : Collector[String] = null
  def initState(runtimeContext : RuntimeContext,
                attributesDescriptor : TypeInformation[Attributes],
                setAttributesDescriptor : TypeInformation[mutable.HashSet[Attributes]],
                mapAttributesDescriptor : TypeInformation[mutable.HashMap[Attributes, Int]] = null) : Unit = {
    val aliveDescriptor = new MapStateDescriptor[Attributes, mutable.HashSet[Attributes]](name+"alive", attributesDescriptor, setAttributesDescriptor)
    val keyCountDescriptor = new MapStateDescriptor[Attributes, Int](name+"keyCount", attributesDescriptor, BasicTypeInfo.INT_TYPE_INFO.asInstanceOf[TypeInformation[Int]])
    attributeDescriptor = attributesDescriptor
    setAttributeDescriptor = setAttributesDescriptor
    runtime = runtimeContext


    alive = runtimeContext.getMapState(aliveDescriptor)
    keyCount = runtimeContext.getMapState(keyCountDescriptor)
    if (numChild > 0) {
      val onholdDescriptor = new MapStateDescriptor[Attributes, mutable.HashMap[Attributes, Int]](name+"onhold", attributesDescriptor, mapAttributesDescriptor)
      onhold = runtimeContext.getMapState(onholdDescriptor)
    }
  }

  def setOut(t : Collector[String], timet : ValueState[Long] = null) : Unit = {
    out = t
    if (timet != null) time = timet
  }

  def addConnection(keys : Array[String], relation : Relation) : Unit = {
    if (numChild > 0) {
      val joinKeyMapDescriptor = new MapStateDescriptor[Attributes, mutable.HashSet[Attributes]](name+"joinKeyMap"+cnt, attributeDescriptor, setAttributeDescriptor)
      val aliveKeyMapDescriptor = new MapStateDescriptor[Attributes, mutable.HashSet[Attributes]](name+"aliveKeyMap"+cnt, attributeDescriptor, setAttributeDescriptor)
      val globalKeyMapDescriptor = new MapStateDescriptor[Attributes, mutable.HashSet[Attributes]](name+"globalAliveKeyMap"+cnt, attributeDescriptor, setAttributeDescriptor)
      cnt = cnt + 1
      val joinKeyMap = runtime.getMapState(joinKeyMapDescriptor)
      val aliveKeyMap = runtime.getMapState(aliveKeyMapDescriptor)
      val globalAliveKeyMap = runtime.getMapState(globalKeyMapDescriptor)
      connection.append((relation, keys, joinKeyMap, aliveKeyMap, globalAliveKeyMap))
    } else throw new Exception("Add connection to non-child node")
  }

  def getAlive(keys : Attributes) : Boolean = {
    if (keyCount.get(keys) > 0) true
    else false
  }

  protected def addElementToIndex(key : Attributes, tuple : Attributes, state : MapState[Attributes, mutable.HashSet[Attributes]]) : Unit = {
    if (state.contains(key)) {
      val temp = state.get(key)
      temp.add(tuple)
    } else {
      val temp = new mutable.HashSet[Attributes]()
      temp.add(tuple)
      state.put(key, temp)
    }
  }

  protected def deleteElementFromIndex(key : Attributes, tuple : Attributes, state : MapState[Attributes, mutable.HashSet[Attributes]]) : Unit = {
    if (state.contains(key)) {
      val temp = state.get(key)
      if (!temp.remove(tuple))
        throw new Exception("Element is not found in the state " + tuple.toString)
      if (temp.isEmpty)
        state.remove(key)
    } else {
      throw new Exception("Element " + tuple.toString + " not in state " + name)
    }
  }

  protected def insertKeyMap(tuple : Attributes) : Unit = {
    val c : Int = testAlive(tuple)
    for (i <- connection) {
      val keys = tuple.projection(i._2)
      if (c == numChild) {
        addElementToIndex(keys, tuple, i._4)
      } else {
        addElementToIndex(keys, tuple, i._3)
      }
    }
  }

  protected def deleteKeyMap(tuple : Attributes) : Unit = {
    val c : Int = testAlive(tuple)
    for (i <- connection) {
      val keys = tuple.projection(i._2)
      if (c == numChild) {
        deleteElementFromIndex(keys, tuple, i._4)
      } else {
        deleteElementFromIndex(keys, tuple, i._3)
      }
    }
  }

  protected def changeToAliveConnection(tuple : Attributes) : Unit = {
    for (i <- connection) {
      val keys = tuple.projection(i._2)
      addElementToIndex(keys, tuple, i._4)
      deleteElementFromIndex(keys, tuple, i._3)
    }
  }

  protected def changeToOnHoldConnection(tuple : Attributes) : Unit = {
    for (i <- connection) {
      val keys = tuple.projection(i._2)
      addElementToIndex(keys, tuple, i._3)
      deleteElementFromIndex(keys, tuple, i._4)
    }
  }

  protected def aliveAdd(tuple : Attributes) : Unit = {
    val projectB = tuple.projection(joinkey)
    if (alive.contains(projectB)) {
      if (!keyCount.contains(projectB))
        throw new Exception("ERROR! Element not found!")
      val tempCount = keyCount.get(projectB)
      keyCount.put(projectB, tempCount+1)
    } else {
      if (keyCount.contains(projectB))
        throw new Exception("ERROR! Should be Zero")
      else keyCount.put(projectB, 1)
    }
    addElementToIndex(projectB, tuple, alive)
    triggerUpdate(tuple, "Insert")

  }

  protected def onholdDelete(tuple : Attributes) : Unit = {
    val projectB = tuple.projection(joinkey)
    if (onhold.contains(projectB)) {
      val temp = onhold.get(projectB)
      if (!temp.contains(tuple))
        throw new Exception("Element is not found in the state")
      else {
        temp.remove(tuple)
        if (temp.isEmpty)
          onhold.remove(projectB)
      }
    } else {
      throw new Exception("ERROR! Element not found in onhold "+ name + " " + tuple.toString)
    }
  }

  protected def aliveDelete(tuple : Attributes) : Unit = {
    val projectB = tuple.projection(joinkey)
    if (!keyCount.contains(projectB))
      throw new Exception("ERROR! Element not found!")
    else {
      val tempCount = keyCount.get(projectB)
      if (tempCount == 1) {
        keyCount.remove(projectB)

      } else
        keyCount.put(projectB, tempCount-1)
      triggerUpdate(tuple, "Delete")
      deleteElementFromIndex(projectB, tuple, alive)
    }

  }

  protected def onholdAdd(tuple : Attributes, st : Int) : Unit = {
    val projectB = tuple.projection(joinkey)
    if (onhold.contains(projectB)) {
      val temp = onhold.get(projectB)
      if (temp.contains(tuple))
        throw new Exception("ERROR! Element already added " + tuple.toString)
      else {
        temp.put(tuple, st)
      }
    } else {
      val temp = new mutable.HashMap[Attributes, Int]()
      temp.put(tuple, st)
      onhold.put(projectB, temp)
    }
  }

  def insert(tuple : Attributes) : Unit = {
    insertKeyMap(tuple)
    val c : Int = testAlive(tuple)
    if (c == numChild) {
      aliveAdd(tuple)
    } else {
      onholdAdd(tuple, c)
    }
  }

  def delete(tuple : Attributes) : Unit = {
    deleteKeyMap(tuple)
    val c : Int = testAlive(tuple)
    if (c == numChild) {
      aliveDelete(tuple)
    } else {
      onholdDelete(tuple)
    }
  }

  /**
   * A function for outputting the result.
   * mode = 0: output the result to null
   * mode = 1: output the result to an external file, bypass the Flink cluster
   * mode = 2: output the result to standard IO, bypass the Flink cluster
   * mode = 3: output the result to flink sink.
   * mode = 4: perform no output
   * mode = 5: perform output with latency in the field _6
   * @param t An iterator for the query result
   * @param operator indicator string for different output type.
   * @param outputPath used for file output.
   */
  def outputResult(t : Iterator[Attributes], operator : String, outputPath : String = ""): Unit = {
    this.deltaEnumMode match {
      case 0 => for (i <- t) i
      case 1 => {
        val fw = new FileWriter(outputPath, true)
        try {
          for (i <- t) fw.write(operator + " " + i + "\n" /* your stuff */)
        }
        finally fw.close()
      }
      case 2 => for (i <- t) println(operator + " " + i)
      case 3 => for (i <- t) out.collect(operator + " " + i)
      case 4 =>
      case 5 => for (i <- t) out.collect(operator + " " + i + " lat: " + (System.currentTimeMillis()-time.value()).toString)
      case _ => throw new NoSuchMethodException("Output Mode " + deltaEnumMode + " is not supported, please check your code")
    }
  }

  protected def triggerUpdate(tuple : Attributes, operator : String = "Insert") : Unit = {
    if (nextRelation == null && this.isOutput) {
      if (operator == "Insert") {
        val t = new fullAttrEnumerator(tuple, "Insert")
        outputResult(t, "+")
      } else {
        val t = new fullAttrEnumerator(tuple, "Delete")
        outputResult(t, "-")
      }
      return
    }
    val key = tuple.projection(joinkey)
    if (operator != "Insert") {
      if (!keyCount.contains(key)) {
        nextRelation.updateOnHold(key, this)
      } else {
        if (this.isOutput && nextRelation.ifGloballyAlive(key, this)) {
          val t = new fullAttrEnumerator(tuple, "Delete")
          outputResult(t, "-")
        }
      }
    } else {
      if (keyCount.get(key) == 1) {
        nextRelation.updateAlive(key, this)
      } else {
        if (this.isOutput && nextRelation.ifGloballyAlive(key, this)) {
          val t = new fullAttrEnumerator(tuple, "Insert")
          outputResult(t, "+")
        }
      }
    }
  }

  def ifGloballyAlive(key : Attributes, relation: Relation): Boolean = {
    var t : TupleConnection = null
    for (i <- connection) {
      if (relation == i._1) {
        t = i
      }
    }
    if (t == null) throw new Exception("Relation Not Found!")
    else t._5.contains(key)
  }

  def testAlive(tuple: Attributes) : Int = {
    if (numChild == 0) 0
    else {
      var cnt = 0
      for (i <- connection) {
        if (i._1.getAlive(tuple.projection(i._2))) cnt = cnt + 1
      }
      cnt
    }
  }

  def getKeyCount(keys : Attributes) : Int = {
    if (!keyCount.contains(keys)) 1
    else keyCount.get(keys)
  }

  def getAnnotation(keys : Attributes) : Double = {
    var annotation = keys.basedannotation
    for (i <- connection) {
      if (!i._1.isOutput) {annotation = annotation * i._1.getKeyCount(keys.projection(i._2))}
    }
    annotation
  }

  def updateAnnotation(keys : Attributes, relation : Relation) : Unit = {
    var index : TupleConnection = null
    for (i <- connection) {
      if (i._1 == relation) index = i
    }
    if (index == null) throw new Exception("Index not found in connection")
    if (index._3.contains(keys)) {
      val temp = index._3.get(keys).toArray
      for (i <- temp) {
        val jk = i.projection(joinkey)
        val tempEle = onhold.get(jk)
        val tempCnt = tempEle.getOrElse(i, throw new Exception("Element not found in the onhold state"))
        i.annotation = getAnnotation(i)
        tempEle.put(i, tempCnt)
      }
    }
    if (index._4.contains(keys)) {
      val temp = index._4.get(keys).toArray
      for (i <- temp) {
        val jk = i.projection(joinkey)
        val tempEle = alive.get(jk)
        if (tempEle.contains(i)) {
          i.annotation = getAnnotation(i)
          if (this.isOutput && (nextRelation == null || nextRelation.ifGloballyAlive(jk, this))) {
            val t = new fullAttrEnumerator(i, "Update")
            outputResult(t, "U-")
          } else {
            if (!this.isOutput)
              throw new NoSuchMethodException(
                "Multiple level non-output attributes with annotated relation are not supported!")
          }
        }
      }
    }
  }

  def updateAlive(keys : Attributes, relation : Relation) : Unit = {
    var index : TupleConnection = null
    for (i <- connection) {
      if (i._1 == relation) index = i
    }
    if (index == null) throw new Exception("Index not found in connection")
    if (index._3.contains(keys)) {
      val temp = index._3.get(keys).toArray
      for (i <- temp) {
        val jk = i.projection(joinkey)
        val tempEle = onhold.get(jk)
        var tempCnt = tempEle.getOrElse(i, throw new Exception("Element not found in the onhold state"))
        tempCnt = tempCnt + 1
        if (tempCnt == numChild) {
          changeToAliveConnection(i)
          onholdDelete(i)
          aliveAdd(i)
        } else {
          tempEle.put(i, tempCnt)
        }
      }
    }
  }

  def updateOnHold(keys : Attributes, relation : Relation) : Unit = {
    var index : TupleConnection = null
    for (i <- connection) {
      if (i._1 == relation)
        index = i
    }
    if (index == null)
      throw new Exception("Index not found in connection")
    if (index._3.contains(keys)) {
      val temp = index._3.get(keys)
      for (i <- temp) {
        val jk = i.projection(joinkey)
        val tempEle = onhold.get(jk)
        var tempCnt = tempEle.getOrElse(i, throw new Exception("Element not found in the onhold state"))
        tempCnt = tempCnt - 1
        tempEle.put(i, tempCnt)
      }
    }
    if (index._4.contains(keys)) {
      val temp = index._4.get(keys).toArray
      for (i <- temp) {
        aliveDelete(i)
        if (numChild > 0) {
          onholdAdd(i, numChild - 1)
          changeToOnHoldConnection(i)
        } else {
          throw new Exception(s"Relation $name should have child node")
        }
      }
    }

  }

  def existsInIndex(key : Attributes, tuple : Attributes, state : MapState[Attributes, mutable.HashSet[Attributes]]) : Boolean = {
    if (state.contains(key)) {
      val temp = state.get(key)
      if (temp.contains(tuple)) true
      else false
    } else {
      false
    }
  }

  def changeGlobalAlive(tuple : Attributes, operation : String = "Insert") : Unit = {
    if (this.numChild == 0) return
    if (operation == "Delete" && (nextRelation != null && nextRelation.ifGloballyAlive(tuple, this)))  return
    for (i <- connection) {
      if (operation == "Insert") {
        val key = tuple.projection(i._2)
        if (!existsInIndex(key, tuple, i._5)) addElementToIndex(key, tuple, i._5)
      } else {
        if (operation == "Delete") {
          val key = tuple.projection(i._2)
          if (existsInIndex(key, tuple, i._5)) deleteElementFromIndex(key, tuple, i._5)
        }
      }
    }
  }

  override def toString: String = {
    "Relation " + name
  }

  def fullAttrEnumerate(keys : Attributes, operation : String = "Insert") : Iterator[Attributes] = new fullAttrEnumerator(keys, operation)

  class fullAttrEnumerator(tuple : Attributes, operation : String = "Insert") extends Iterator[Attributes] {

    var iter1 : Iterator[Attributes] = null
    var iter2 : Iterator[Attributes] = null
    var iter3 : Iterator[Attributes] = null
    var current1 : Attributes = null
    var current2 : Attributes = null
    var current3 : Attributes = null
    var init : Boolean = false
    var cnt = 0

    // cache for current1 join current2
    var current1JoinCurrent2 : Attributes = null

    def initialChild(r : TupleConnection, tuple : Attributes) : (Iterator[Attributes], Attributes) = {
      val projectionKey = tuple.projection(r._2)
      val itert = new r._1.joinKeyEnumerator(projectionKey, operation)
      var currentT : Attributes = null
      if (itert.hasNext) currentT = itert.next()
      else throw new Exception("The iterator has no output!")
      return (itert, currentT)
    }

    def initIter2() : Unit = {
      val r = connection(0)
      val t = initialChild(r, tuple)
      current2 = t._2
      iter2 = t._1
    }

    def initIter3() : Unit = {
      val r = connection(1)
      val t = initialChild(r, tuple)
      if (connection(0)._1.isOutput) {
        current3 = t._2
        iter3 = t._1
      } else {
        current2 = t._2
        iter2 = t._1
      }
    }

    def open() : Unit = {
      init = true
      if (Relation.this.nextRelation == null) {
        cnt = 1
        if (Relation.this.alive.isEmpty) {
          current1 = null
          return
        }
        iter1 = Relation.this.joinKeyEnumerate(tuple, operation)
        current1 = iter1.next()
        return
      } else {
        changeGlobalAlive(tuple, operation)
        val joinKey = tuple.projection(Relation.this.joinkey)
        iter1 = Relation.this.nextRelation.deltaEnumerate(joinKey, Relation.this, "Delta")
        current1 = iter1.next()
        cnt = 1
      }
      if (1 <= connection.length && connection(0)._1.isOutput) {
        initIter2()
        cnt = cnt + 1
      }
      if (2 <= connection.length && connection(1)._1.isOutput) {
        initIter3()
        cnt = cnt + 1
        // we need current1JoinCurrent2 only when cnt = 3
        current1JoinCurrent2 = current1.join(current2)
      }
      if (3 <= connection.length) {
        throw new NoSuchMethodException("Join tree with children node > 3 has not been supported")
      }
    }


    override def hasNext: Boolean = {
      if (!init) open()
      if (cnt == 1) !(current1 == null)
      else if (cnt == 2) !(current1 == null && current2 == null)
      else if (cnt == 3) !(current1 == null && current2 == null && current3 == null)
      else throw new Exception("Join tree with children node > 3 has not been supported")
    }

    override def next(): Attributes = {
      if (!init) open()
      if (cnt == 3) {
        val nextResult: Attributes = current1JoinCurrent2.join(current3).join(tuple)
        if (iter3.hasNext) {
          current3 = iter3.next()
        } else {
          if (iter2.hasNext) {
            current2 = iter2.next()
            current1JoinCurrent2 = current1.join(current2)
            initIter3()
          } else {
            if (iter1.hasNext) {
              current1 = iter1.next()
              initIter3()
              initIter2()
              current1JoinCurrent2 = current1.join(current2)
            } else {
              current1 = null
              current2 = null
              current3 = null
            }
          }
        }
        nextResult
      } else {
        if (cnt == 1) {
          val nextResult = current1.join(tuple)
          if (iter1.hasNext) current1 = iter1.next()
          else current1 = null
          nextResult
        }
        else if (cnt == 2) {
          val nextResult = current1.join(current2).join(tuple)
          if (iter2.hasNext) {
            current2 = iter2.next()
          } else {
            if (iter1.hasNext) {
              current1 = iter1.next()
              initIter2()
            } else {
              current1 = null
              current2 = null
            }
          }
          nextResult
        } else throw new Exception("More than two children is not supported")
      }
    }
  }

  def deltaEnumerate(keys : Attributes, relation : Relation, operation : String = "Insert") : Iterator[Attributes] = new deltaEnumerator(keys, relation, operation)

  class deltaEnumerator(keys : Attributes, relation : Relation, operation : String = "Insert") extends Iterator[Attributes] {
    var iter1 : Iterator[Attributes] = null
    var iter2 : Iterator[Attributes] = null
    var iter3 : Iterator[Attributes] = null
    var original : Attributes = null
    var current1 : Attributes = null
    var current2 : Attributes = null
    var current3 : Attributes = null
    var init : Boolean = false
    var cnt = 0
    var ret : TupleConnection = null

    // cache for current1 join current2
    var current1JoinCurrent2: Attributes = null

    def initIter3() : Unit = {
      val key = current1.projection(Relation.this.joinkey)
      iter3 = Relation.this.nextRelation.deltaEnumerate(key, Relation.this, operation)
      current3 = iter3.next()
    }

    private def testChild() : Boolean = {
      var connectCount = 0
      if (connection(connectCount) == ret) connectCount = connectCount + 1
      connection(connectCount)._1.isOutput
    }

    def initIter2() : Boolean = {
      var connectCount = 0
      if (connection(connectCount) == ret) connectCount = connectCount + 1
      val r = connection(connectCount)
      if (r._1.isOutput) {
        val t = initialChild(r, current1)
        current2 = t._2
        iter2 = t._1
        true
      } else {
        false
      }
    }

    def initialChild(r : TupleConnection, tuple : Attributes) : (Iterator[Attributes], Attributes) = {
      val projectionKey = tuple.projection(r._2)
      val itert = new r._1.joinKeyEnumerator(projectionKey, "Delta")
      var currentT : Attributes = null
      if (itert.hasNext) currentT = itert.next()
      else throw new Exception("The iterator has no output!")
      return (itert, currentT)
    }

    def open() : Unit = {
      init = true
      cnt = 0
      if (keys == null) throw new NoSuchMethodException("For Delta enumeration, the keys cannot be empty.")

      for (i <- connection) {
        if (i._1 == relation) ret = i
      }
      iter1 = ret._5.get(keys).toIterator
      cnt = cnt + 1

      if (iter1.hasNext) {
        current1 = iter1.next()
        if (2 == connection.length) {
          if (initIter2()) cnt = cnt + 1
        }
        if (3 <= connection.length) {
          throw new NoSuchMethodException("Join tree with children node > 3 has not been supported")
        }
        if (Relation.this.nextRelation != null) {
          initIter3()
          cnt = cnt + 1
          // we need current1JoinCurrent2 only when cnt = 3
          current1JoinCurrent2 = current1.join(current2)
        }
      } else {
        throw new Exception("The iterator has no output! Something went wrong!")
      }
    }

    override def hasNext: Boolean = {
      if (!init) open()
      if (cnt == 1) !(current1 == null)
      else if (cnt == 2) {
        if (2 == connection.length && testChild()) !(current1 == null && current2 == null)
        else !(current1 == null && current3 == null)
      }
      else if (cnt == 3) !(current1 == null && current2 == null && current3 == null)
      else throw new Exception("Join tree with children node > 3 has not been supported")
    }

    override def next(): Attributes = {
      if (!init) open()
      if (cnt == 3) {
        val nextResult: Attributes = current1JoinCurrent2.join(current3)
        if (iter3.hasNext) {
          current3 = iter3.next()
        } else {
          if (iter2.hasNext) {
            current2 = iter2.next()
            current1JoinCurrent2 = current1.join(current2)
            initIter3()
          } else {
            if (iter1.hasNext) {
              current1 = iter1.next()
              initIter3()
              initIter2()
              current1JoinCurrent2 = current1.join(current2)
            } else {
              current1 = null
              current2 = null
              current3 = null
            }
          }
        }
        nextResult
      } else {
        if (cnt == 1) {
          val nextResult = current1
          if (iter1.hasNext) current1 = iter1.next()
          else current1 = null
          nextResult
        }
        else if (cnt == 2) {
          var nextResult : Attributes = null
          if (2 == connection.length && testChild()) {
            nextResult = current1.join(current2)
            if (iter2.hasNext) {
              current2 = iter2.next()
            } else {
              if (iter1.hasNext) {
                current1 = iter1.next()
                initIter2()
              } else {
                current1 = null
                current2 = null
              }
            }
          } else {
            nextResult = current1.join(current3)
            if (iter3.hasNext) {
              current3 = iter3.next()
            } else {
              if (iter1.hasNext) {
                current1 = iter1.next()
                initIter3()
              } else {
                current1 = null
                current3 = null
              }
            }
          }
          nextResult
        } else throw new Exception("More than two children is not supported")
      }
    }
  }

  def joinKeyEnumerate(keys : Attributes, operation : String = "Delta") : Iterator[Attributes] = new joinKeyEnumerator(keys, operation)

  //TODO When root is the only output relation, the annotation of root node are incorrect.
  // Temp fix: add another relation on the top of root node.

  class joinKeyEnumerator(keys : Attributes, operation : String = "Delta") extends Iterator[Attributes] {
    var iter1 : Iterator[Attributes] = null
    var iter2 : Iterator[Attributes] = null
    var iter3 : Iterator[Attributes] = null
    var current1 : Attributes = null
    var current2 : Attributes = null
    var current3 : Attributes = null
    var init : Boolean = false
    var cnt = 0

    // cache for current1 join current2
    var current1JoinCurrent2: Attributes = null

    def initialChild(r : TupleConnection, tuple : Attributes) : (Iterator[Attributes], Attributes) = {
      val projectionKey = tuple.projection(r._2)
      val itert = new r._1.joinKeyEnumerator(projectionKey, operation)
      var currentT : Attributes = null
      if (itert.hasNext) currentT = itert.next()
      else throw new Exception("The iterator has no output!")
      return (itert, currentT)
    }

    def initIter2() : Unit = {
      val r = connection(0)
      val t = initialChild(r, current1)
      current2 = t._2
      iter2 = t._1
    }

    def initIter3() : Unit = {
      val r = connection(1)
      val t = initialChild(r, current1)
      if (connection(0)._1.isOutput) {
        current3 = t._2
        iter3 = t._1
      } else {
        current2 = t._2
        iter2 = t._1
      }
    }

    def open() : Unit = {
      init = true
      cnt = 0
      val tempval = if (keys == null) {
        alive.keys().asScala.iterator
      } else {
        alive.get(keys).toIterator
      }
      iter1 = tempval
      cnt = cnt + 1
      if (iter1.hasNext) {
        current1 = iter1.next()
        changeGlobalAlive(current1, operation)
        if (1 <= connection.length && connection(0)._1.isOutput) {
          initIter2()
          cnt = cnt + 1
        }
        if (2 <= connection.length && connection(1)._1.isOutput) {
          initIter3()
          cnt = cnt + 1
          // we need current1JoinCurrent2 only when cnt = 3
          current1JoinCurrent2 = current1.join(current2)
        }
        if (3 <= connection.length) {
          throw new NoSuchMethodException("Join tree with children node > 3 has not been supported")
        }
      } else {
        throw new Exception("The iterator has no output! Something went wrong!")
      }
    }


    override def hasNext: Boolean = {
      if (!init) open()
      if (cnt == 1) !(current1 == null)
      else if (cnt == 2) !(current1 == null && current2 == null)
      else if (cnt == 3) !(current1 == null && current2 == null && current3 == null)
      else throw new Exception("Join tree with children node > 3 has not been supported")
    }

    override def next(): Attributes = {
      if (!init) open()
      if (cnt == 3) {
        val nextResult: Attributes = current1JoinCurrent2.join(current3)
        if (iter3.hasNext) {
          current3 = iter3.next()
        } else {
          if (iter2.hasNext) {
            current2 = iter2.next()
            current1JoinCurrent2 = current1.join(current2)
            initIter3()
          } else {
            if (iter1.hasNext) {
              current1 = iter1.next()
              changeGlobalAlive(current1, operation)
              initIter2()
              current1JoinCurrent2 = current1.join(current2)
              initIter3()
            } else {
              current1 = null
              current2 = null
              current3 = null
            }
          }
        }
        nextResult
      } else {
        if (cnt == 1) {
          val nextResult = current1
          if (iter1.hasNext) {
            current1 = iter1.next()
            changeGlobalAlive(current1, operation)
          }
          else current1 = null

          nextResult
        }
        else if (cnt == 2) {
          val nextResult = current1.join(current2)
          if (iter2.hasNext) {
            current2 = iter2.next()
          } else {
            if (iter1.hasNext) {
              current1 = iter1.next()
              changeGlobalAlive(current1, operation)
              initIter2()
            } else {
              current1 = null
              current2 = null
            }
          }
          nextResult
        } else throw new Exception("More than two children is not supported")
      }
    }
  }


}
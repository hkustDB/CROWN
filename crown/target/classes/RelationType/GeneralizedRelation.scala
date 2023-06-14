package RelationType

abstract class GeneralizedRelation(name : String, joinkey : Array[String], nextRelation : Relation, override val deltaEnumMode: Int, numChild : Int = 0)
  extends Relation(name, joinkey, nextRelation, deltaEnumMode, numChild) {

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

  override def insert(tuple : Attributes) : Unit = {
    throw new NoSuchMethodError("No insertion is allowed in the Generalized relation")
  }

  override def delete(tuple : Attributes) : Unit = {
    throw new NoSuchMethodError("No Deletion is allowed in the Generalized relation")
  }

  def testExists(tuple : Attributes) : Boolean = {
    alive.contains(tuple) || onhold.contains(tuple)
  }

  override protected def insertKeyMap(tuple: Attributes): Unit = {
    for (i <- connection) {
      val keys = tuple.projection(i._2)
      addElementToIndex(keys, tuple, i._3)
    }
  }

  override def updateAlive(keys : Attributes, relation : Relation) : Unit = {
    if (testExists(keys) == false) {
      insertKeyMap(keys)
      onholdAdd(keys, 0)
    }
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

  override def updateOnHold(keys : Attributes, relation : Relation) : Unit = {
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
        if (tempCnt == 0) {
          onholdDelete(keys)
          deleteKeyMap(keys)
        }
        tempEle.put(i, tempCnt)
      }
    }
    if (index._4.contains(keys)) {
      val temp = index._4.get(keys).toArray
      for (i <- temp) {
        aliveDelete(i)
        onholdAdd(i, numChild-1)
        changeToOnHoldConnection(i)
        if (numChild == 0) {
          throw new Exception("Generalized relation cannot be a leaf node.")
        }
      }
    }

  }

  override def toString: String = {
    "Relation " + name
  }

}

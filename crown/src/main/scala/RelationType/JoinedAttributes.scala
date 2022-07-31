package RelationType


import scala.collection.mutable.ListBuffer

class JoinedAttributes(basedannotation : Double) extends Attributes(null, null, basedannotation)  {
  type VALUE = (String, Any)
  var valueList : List[(String, Any)] = List[(String, Any)]()
  def this(attr : Attributes) = {
    this(attr.annotation)
    val lb = new ListBuffer[(String, Any)]
    for (i <- attr.keys.indices) {
      lb.append((attr.keys(i), attr.values(i)))
    }
    valueList = lb.toList
  }

  def this(attr : JoinedAttributes) = {
    this(attr.annotation)
    valueList = attr.valueList
  }

  def this(list : List[(String, Any)], annotation : Double = 1.0) = {
    this(annotation)
    valueList = list
  }

  override def apply(attr : String) : Any = {
    val temp = valueList.find(p => p._1 == attr)
    temp match {
      case Some(t) => t._2
      case _ => throw new NullPointerException("Null Point error! Try to Get " + attr)
    }
  }

  def getAnnotation : Double = annotation

  override def join(that : Attributes) : JoinedAttributes = {
    if (that == null) return this

    that match {
      case joinedAttributes: JoinedAttributes =>
        var tempList = valueList
        for (i <- joinedAttributes.valueList)
          if (!tempList.exists(p => p._1 == i._1)) {
            tempList = i :: tempList
          }
        new JoinedAttributes(tempList, joinedAttributes.annotation*this.annotation)
      case _ =>
        if (that.joinedList != null) this.join(that.joinedList)
        var tempList = valueList
        for (i <- that.keys.indices) {
          if (!tempList.exists(p => p._1 == that.keys(i))) {
            tempList = (that.keys(i), that.values(i)) :: tempList
          }
        }
        new JoinedAttributes(tempList, this.annotation * that.annotation)
    }
  }

  override def projection(p_keys: Array[String]): Attributes = {
    var tempList = valueList.filter(p => p_keys.contains(p._1))
    new JoinedAttributes(tempList, this.annotation)
  }

  override def equals(obj: Any): Boolean = {
    obj match {
      case jattr: JoinedAttributes =>
        valueList.length == jattr.valueList.length && valueList.forall(
          kv => jattr.valueList.find(p => p._1 == kv._1).exists(p => p._2 == kv._2))
      case attr: Attributes =>
        valueList.length == attr.keys.length && valueList.forall(kv => {
          val i = attr.keys.indexOf(kv._1)
          i >= 0 && attr.values(i) == kv._2
        })
      case _ => false
    }
  }

  override def hashCode(): Int = {
    if (hashcodeBuffer == 0) {
      var result = 0
      valueList.foreach(t => result = result ^ computeHashCode(t._1, t._2))
      hashcodeBuffer = result
    }
    hashcodeBuffer
  }

  override def containsKey(attr : String) : Boolean = valueList.exists(p => p._1 == attr)

  override def rename(_orig: String, _new: String) : Unit = {
    var dropped = false
    var old_value: Any = null
    def dropOld(l: List[(String, Any)]): List[(String, Any)] = l match {
      case h :: t =>
        if (h._1 == _orig) {
          dropped = true
          old_value = h._2
          t
        } else {
          dropOld(t)
        }
      case Nil => List.empty[(String, Any)]
    }
    valueList = (valueList.takeWhile(kv => kv._1 != _orig)) ::: dropOld(valueList)
    if (dropped) {
      valueList = (_new, old_value) :: valueList
    } else {
      throw new NoSuchElementException(s"The Database Scheme does not contain attribute ${_orig}")
    }
  }

  override def toString: String = {
    if (equalDouble(annotation, 1.0)) valueList.mkString(" , ")
    else valueList.mkString(" , ") + s" Annotation : $annotation"
  }
}

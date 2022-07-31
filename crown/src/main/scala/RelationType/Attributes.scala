package RelationType

import scala.collection.mutable.ArrayBuffer

case class Attributes(values : Array[Any], keys : Array[String], basedannotation : Double = 1.0) extends Serializable {
  var annotation : Double = basedannotation
  var joinedList : JoinedAttributes = null
  var hashcodeBuffer : Int = 0
  def apply(attr: String): Any = {
    val i = keys.indexOf(attr)
    if (i != -1)
      values(i)
    else
      throw new NullPointerException(
        "Null Point error! Try to Get " + attr)
  }

  def projection(p_keys : Array[String]) : Attributes = {
    var tempArray : ArrayBuffer[Any] = new ArrayBuffer()
    for (i <- p_keys) {
      tempArray.append(this.apply(i))
    }
    new Attributes(tempArray.toArray, p_keys, annotation)
  }

  def join(that : Attributes) : JoinedAttributes = {
    that match {
      case joinedAttributes: JoinedAttributes =>
        joinedAttributes.join(this)
      case _ =>
        if (joinedList == null) joinedList = new JoinedAttributes(this)
        joinedList.join(that)
    }
  }

  override def equals(obj: Any): Boolean = {
    obj match {
      case joinedAttributes: JoinedAttributes =>
        val thatValueList = joinedAttributes.valueList
        thatValueList.size == values.length && thatValueList.forall(t => {
          val index = this.keys.indexOf(t._1)
          index >= 0 && values(index) == t._2
        })
      case attr: Attributes =>
        for (i <- keys.indices) {
          val j = attr.keys.indexOf(keys(i))
          if (j == -1) return false
          if (attr.values(j) != values(i)) return false
        }
        true
      case _ =>
        false
    }
  }

  override def hashCode(): Int = {
    if (hashcodeBuffer == 0) {
      var result = 0
      for (i <- values.indices) {
        result = result ^ computeHashCode(keys(i), values(i))
      }
      hashcodeBuffer = result
    }
    hashcodeBuffer
  }

  def containsKey(attr : String) : Boolean = keys.contains(attr)

  def rename(_orig: String, _new: String) : Unit = {
    val index = keys.indexOf(_orig)
    if (index == -1)
      throw new NoSuchElementException(s"The Database Scheme does not contain attribute ${_orig}")
    keys(index) = _new
  }

  override def toString: String = {
    if (equalDouble(annotation, 1.0)) s"${values.mkString(" , ")}, ${keys.mkString(" , ")}"
    else s"${values.mkString(" , ")}, ${keys.mkString(" , ")}, Annotation : $annotation"
  }

  def equalDouble(v1 : Double, v2 : Double) : Boolean = {
    (v1 - v2) * (v1 - v2) < 1e-6
  }

  def computeHashCode(fieldName: String, fieldValue: Any): Int = {
    val valueHashCode = fieldValue match {
      case i: Int => i
      case s: String => s.##
      case l: Long => (l ^ 0xFFFFFFFF).toInt ^ (l >> 32).toInt
      case _ => throw new UnsupportedOperationException(s"please implement your hashcode function for ${fieldValue.getClass}")
    }
    fieldName.## * valueHashCode
  }
}

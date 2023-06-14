import scala.collection.mutable

package object Util {
  val date_format = new java.text.SimpleDateFormat("yyyy-MM-dd")
  val t1 = date_format.parse("1994-12-31")
  val t2 = date_format.parse("1997-01-01")
  var keyCount = 0
  val KeyListMap = Map( 32 -> List(13, 4, 44, 8, 6, 29, 14, 24, 51, 32, 74, 22, 9, 49, 76, 41, 10, 15, 108, 18, 17, 1, 45, 27, 57, 11, 65, 80, 3, 16, 31, 2),
    16 -> List(4, 8, 6, 14, 32, 22, 9, 41, 10, 18, 1, 27, 11, 65, 3, 2),
    8 -> List(4, 6, 22, 9, 10, 1, 11, 2),
    4 -> List(4, 9, 1, 2),
    2 -> List(4, 1),
    1 -> List(0))
  val paraMap = Map(32 -> (8, 4), 16 -> (4, 4), 8 -> (2, 4), 4 -> (2, 2), 2 -> (2, 1), 1 -> (1, 1))
  def arrayToMap(keyArray : Array[String], valueArray : Array[Any]): mutable.HashMap[String, Any] = {
    val temp = mutable.HashMap[String, Any]()
    for (i <- keyArray.indices) {
      temp.put(keyArray(i), valueArray(i))
    }
    temp
  }
}

package experiments.data.utils

object Extensions {
    implicit def convertProductToStringArray(p: Product): Array[String] =
        p.productIterator.map(_.toString).toArray

    implicit def convertStringListToStringArray(l: List[String]): Array[String] =
        l.toArray
}

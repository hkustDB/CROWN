package experiments.data.validate.dbtoastercpp.length3_filter

import experiments.data.validate.Validator

import java.io.{BufferedReader, FileInputStream, InputStreamReader}
import scala.collection.mutable
import scala.xml.XML

object ResultValidator extends Validator {
    override def validate(args: Array[String]): Unit = {
        val resultPath = args(0)
        val dataPath = args(1)
        val filterValue = args(2).toInt

        val d = dbtoastercppApproach(resultPath)
        val t = trivialApproach(dataPath, filterValue)

        // both approaches have the same result size(non-zero cnt paths)
        assert(d.size == t.size)
        // all the paths have the same cnt value
        assert(d.forall(kv => kv._2 == t(kv._1)))
    }

    def trivialApproach(path: String, filterValue: Int): Map[(Int, Int, Int, Int), Int] = {
        val reader = new BufferedReader(new InputStreamReader(new FileInputStream(path + "data1.csv")))

        // {(1, 2) -> 2, (1, 3) -> 1, (2, 3) -> 1, (3, 4) -> 1}
        val table = mutable.HashMap.empty[(Int, Int), Int]

        var line = reader.readLine()
        while (line != null) {
            val row = line.split(",").tail
            row.head match {
                case "0" =>
                    val edge = (row(1).toInt, row(2).toInt)
                    table(edge) = table(edge) - 1
                case "1" =>
                    val edge = (row(1).toInt, row(2).toInt)
                    table(edge) = table.getOrElseUpdate(edge, 0) + 1
                case _ =>
            }
            line = reader.readLine()
        }

        // {1 -> {(1, 2) -> 2, (1, 3) -> 1}, 2 -> {(2, 3) -> 1}, 3 -> {(3, 4) -> 1}}
        val grouped = table.groupBy(t => t._1._1)

        // {1 -> [2, 2, 3], 2 -> [3], 3 -> [4]}
        val graph = grouped.mapValues(inner => inner.flatMap(t => List.fill(t._2)(t._1._2)))

        // [(1, 2, 3, 4), (1, 2, 3, 4)]
        val list = for {
            src <- graph.keySet.toList
            via1 <- graph(src)
            via2 <- graph.getOrElse(via1, List.empty[Int])
            dst <- graph.getOrElse(via2, List.empty[Int])
            if dst > filterValue
        } yield (src, via1, via2, dst)

        // {(1, 2, 3, 4) -> 2}
        list.groupBy(t => t).mapValues(s => s.size).toMap
    }

    def dbtoastercppApproach(path: String): Map[(Int, Int, Int, Int), Int] = {
        val doc = XML.loadFile(path)

        (for {
            item <- doc \\ "item"
        } yield {
            val src = (item \ "A_SRC").text.toInt
            val via1 = (item \ "A_DST").text.toInt
            val via2 = (item \ "C_SRC").text.toInt
            val dst = (item \ "C_DST").text.toInt
            val cnt = (item \ "__av").text.toInt
            (src, via1, via2, dst) -> cnt
        }).toMap
    }
}

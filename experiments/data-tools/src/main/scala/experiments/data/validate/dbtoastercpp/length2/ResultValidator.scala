package experiments.data.validate.dbtoastercpp.length2

import experiments.data.validate.Validator

import java.io.{BufferedReader, FileInputStream, InputStreamReader}
import scala.collection.mutable
import scala.xml.XML

object ResultValidator extends Validator {
    override def validate(args: Array[String]): Unit = {
        val resultPath = args(0)
        val dataPath = args(1)

        val d = dbtoastercppApproach(resultPath)
        val t = trivialApproach(dataPath)

        // both approaches have the same result size(non-zero cnt paths)
        assert(d.size == t.size)
        // all the paths have the same cnt value
        assert(d.forall(kv => kv._2 == t(kv._1)))
    }

    def trivialApproach(path: String): Map[(Int, Int, Int), Int] = {
        val reader = new BufferedReader(new InputStreamReader(new FileInputStream(path + "data1.csv")))

        // {(1, 2) -> 2, (1, 3) -> 1, (2, 3) -> 1, (3, 4) -> 1}
        val table = mutable.HashMap.empty[(Int, Int), Int]

        var line = reader.readLine()
        while (line != null) {
            val row = line.split(",").tail
            val edge = (row(1).toInt, row(2).toInt)
            row.head match {
                case "0" => table(edge) = table(edge) - 1
                case "1" => table(edge) = table.getOrElseUpdate(edge, 0) + 1
                case _ =>
            }
            line = reader.readLine()
        }

        // {1 -> {(1, 2) -> 2, (1, 3) -> 1}, 2 -> {(2, 3) -> 1}, 3 -> {(3, 4) -> 1}}
        val grouped = table.groupBy(t => t._1._1)

        // {1 -> [2, 2, 3], 2 -> [3], 3 -> [4]}
        val graph = grouped.mapValues(inner => inner.flatMap(t => List.fill(t._2)(t._1._2)))

        // [(1, 2, 3), (1, 2, 3), (2, 3, 4)]
        val list = for {
            src <- graph.keySet.toList
            via <- graph(src)
            dst <- graph.getOrElse(via, List.empty[Int])
        } yield (src, via, dst)

        // {(1, 2, 3) -> 2, (2, 3, 4) -> 1}
        list.groupBy(t => t).mapValues(s => s.size).toMap
    }

    def dbtoastercppApproach(path: String): Map[(Int, Int, Int), Int] = {
        val doc = XML.loadFile(path)

        (for {
            item <- doc \\ "item"
        } yield {
            val src = (item \ "A_SRC").text.toInt
            val via = (item \ "A_DST").text.toInt
            val dst = (item \ "B_DST").text.toInt
            val cnt = (item \ "__av").text.toInt
            (src, via, dst) -> cnt
        }).toMap
    }
}

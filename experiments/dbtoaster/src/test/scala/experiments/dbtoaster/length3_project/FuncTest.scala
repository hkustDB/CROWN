package experiments.dbtoaster.length3_project

import ddbt.lib.Helper.ExperimentHelperListener
import org.apache.hadoop.conf.Configuration
import org.apache.hadoop.fs.{FileSystem, Path}
import org.junit.Assert._
import org.junit._

import java.io.{BufferedReader, InputStreamReader}
import java.util.Properties
import scala.collection.mutable

class FuncTest {
    var properties = new Properties()

    @Before
    def prepare(): Unit = {
        properties.load(getClass.getClassLoader.getResourceAsStream("length3_project.config.properties"))
    }

    @Test
    def testFunc(): Unit = {
        val trivialResult = trivialApproach(properties)
        val dbtoasterResult = dbtoasterApproach(properties)

        assertTrue(trivialResult.size == dbtoasterResult.size)
        trivialResult.foreach { case (tuple, cnt) => assertTrue(dbtoasterResult(tuple) == cnt) }
    }

    def trivialApproach(properties: Properties): Map[(Int, Int), Int] = {
        val path = properties.getProperty("hdfs.data.path")
        val data = new Path(s"$path/data.csv")
        val configuration = new Configuration()
        val fileSystem = FileSystem.get(configuration)
        val reader = new BufferedReader(new InputStreamReader(fileSystem.open(data)))

        // {(1, 2) -> 2, (1, 3) -> 1, (2, 3) -> 1, (3, 4) -> 1}
        val table = mutable.HashMap.empty[(Int, Int), Int]

        var line = reader.readLine()
        while (line != null) {
            val row = line.split(",").tail
            val edge = (row(1).toInt, row(2).toInt)
            row.head match {
                case "0" => table(edge) = table(edge) - 1
                case "1" => table(edge) = table.getOrElseUpdate(edge, 0) + 1
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
        } yield (via1, via2)

        // {(1, 2, 3, 4) -> 2}
        list.distinct.map(t => (t, 1)).toMap
    }

    def dbtoasterApproach(properties: Properties): Map[(Int, Int), Int] = {
        var result: Map[(Int, Int), Int] = null
        val listener = new ExperimentHelperListener {
            override def onSnapshot(snapshot: List[Any]): Unit = {
                result = snapshot.head.asInstanceOf[Map[(Long, Long), Long]]
                    .map(t => (t._1._1.toInt, t._1._2.toInt) -> (if (t._2.toInt > 0) 1 else 0))
            }

            override def onExecutionTime(time: Double): Unit = {}
        }

        Query.exec(properties.getProperty("query.execute.args").split(" "), listener)
        result
    }
}

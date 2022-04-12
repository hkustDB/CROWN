package experiments.dbtoaster.length3_filter

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
        properties.load(getClass.getClassLoader.getResourceAsStream("length3_filter.config.properties"))
    }

    @Test
    def testFunc(): Unit = {
        val trivialResult = trivialApproach(properties)
        val dbtoasterResult = dbtoasterApproach(properties)

        assertTrue(trivialResult.size == dbtoasterResult.size)
        trivialResult.foreach { case (tuple, cnt) => assertTrue(dbtoasterResult(tuple) == cnt) }
    }

    def trivialApproach(properties: Properties): Map[(Int, Int, Int, Int), Int] = {
        val filterValue = properties.getProperty("filter.condition.value").toInt
        val path = properties.getProperty("hdfs.data.path")
        val data = new Path(s"$path/data.csv")
        val configuration = new Configuration()
        val fileSystem = FileSystem.get(configuration)
        val reader = new BufferedReader(new InputStreamReader(fileSystem.open(data)))

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

        val grouped = table.groupBy(t => t._1._1)

        val graph = grouped.mapValues(inner => inner.flatMap(t => List.fill(t._2)(t._1._2)))

        val list = for {
            src <- graph.keySet.toList
            via1 <- graph(src)
            via2 <- graph.getOrElse(via1, List.empty[Int])
            dst <- graph.getOrElse(via2, List.empty[Int])
            if dst > filterValue
        } yield (src, via1, via2, dst)

        list.groupBy(t => t).mapValues(s => s.size)
    }

    def dbtoasterApproach(properties: Properties): Map[(Int, Int, Int, Int), Int] = {
        var result: Map[(Int, Int, Int, Int), Int] = null
        val listener = new ExperimentHelperListener {
            override def onSnapshot(snapshot: List[Any]): Unit = {
                result = snapshot.head.asInstanceOf[Map[(Long, Long, Long, Long), Long]]
                    .map(t => (t._1._1.toInt, t._1._2.toInt, t._1._3.toInt, t._1._4.toInt) -> t._2.toInt)
            }

            override def onExecutionTime(time: Double): Unit = {}
        }

        Query.exec(properties.getProperty("query.execute.args").split(" "), listener)
        result
    }
}

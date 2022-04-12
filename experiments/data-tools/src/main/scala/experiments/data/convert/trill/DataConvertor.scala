package experiments.data.convert.trill

import experiments.data.convert.Convertor

import java.io.{BufferedReader, FileInputStream, InputStreamReader}
import scala.collection.mutable
import experiments.data.utils.CsvFileWriter._
import experiments.data.utils.Extensions._


object DataConvertor extends Convertor {
    override def convert(args: Array[String]): Unit = {
        val src = args(0)
        val dst = args(1)

        val reader: BufferedReader = new BufferedReader(new InputStreamReader(new FileInputStream(src)))
        var line = reader.readLine()
        var time = 1
        val map = mutable.HashMap.empty[List[String], List[Int]]

        def remain(): LazyList[List[String]] = {
            if (line == null)
                LazyList.empty[List[String]]
            else {
                var optTuple = lineToTuple(line)
                line = reader.readLine()

                // loop until we find a valid tuple
                while (optTuple.isEmpty) {
                    optTuple = lineToTuple(line)
                    line = reader.readLine()
                }

                optTuple.get #:: remain()
            }
        }

        def lineToTuple(line: String): Option[List[String]] = {
            val fields = line.split(",")
            val t = fields.tail.toList
            if (fields(0) == "+") {
                map(t) = time :: map.getOrElse(t, List())
                val result = time.toString :: "0" :: t
                time += 1
                Some(result)
            } else if (fields(0) == "-") {
                val result = time.toString :: map(t).head.toString :: t
                map(t) = map(t).tail
                time += 1
                Some(result)
            } else {
                // skip this line if we encounter a "*" at the begin
                None
            }
        }

        remain().writeToCsvFile(dst)
    }
}

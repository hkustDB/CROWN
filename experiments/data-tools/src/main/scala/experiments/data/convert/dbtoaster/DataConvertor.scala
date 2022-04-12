package experiments.data.convert.dbtoaster

import experiments.data.convert.Convertor
import experiments.data.utils.CsvFileWriter.createCsvFileWriterForList

import java.io.{BufferedWriter, FileOutputStream, OutputStreamWriter}
import scala.collection.mutable.{ArrayBuffer, ListBuffer}
import scala.io.Source

object DataConvertor extends Convertor {
    override def convert(args: Array[String]): Unit = {
        val src = args(0)
        val dst = args(1)

        // this value is necessary because when we have more than 1 stream to read a single file,
        // then each line in that file actually represents ${countMultiplier} lines in runtime.
        // we need to accumulate the line count and divide by the batchSize to determine when
        // to trigger a full enumeration
        val countMultiplier = args(2).toInt
        val batchSize = args(3).toInt

        // write when to trigger full enum to this file
        val enumPointsFile = args(4)

        val source = Source.fromFile(src)
        try {
            var cnt = 0
            val lines = source.getLines().toList
            val result = ListBuffer.empty[Array[String]]
            val enumPoints = ArrayBuffer.empty[Int]
            lines.foreach(line => {
                val strings = line.split(",")
                if (strings.head == "+") {
                    cnt += 1
                    val buffer = new ArrayBuffer[String](strings.length + 2)
                    buffer.addOne(cnt.toString)
                    // op = 1 for insert
                    buffer.addOne("1")
                    buffer.addAll(strings.slice(1, strings.length))
                    result.addOne(buffer.toArray)
                } else if (strings.head == "-") {
                    cnt += 1
                    val buffer = new ArrayBuffer[String](strings.length + 2)
                    buffer.addOne(cnt.toString)
                    // op = 0 for delete
                    buffer.addOne("0")
                    buffer.addAll(strings.slice(1, strings.length))
                    result.addOne(buffer.toArray)
                } else if (strings.head == "*") {
                    // encounter a line begin with "*", trigger full enum
                    val passedEvents = cnt * countMultiplier
                    // for example, if countMultiplier = 3 (3 streams read a same file)
                    // if we encounter an * at line 4(index begin at 1)
                    // then we need to trigger full enum after 9 events have been processed
                    // we decide to trigger after batch #2 have been processed
                    val batchNum = passedEvents / batchSize
                    enumPoints.addOne(batchNum)
                } else {
                    // unknown op
                }
            })

            val writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(enumPointsFile)))
            writer.write(enumPoints.mkString(","))
            writer.flush()
            writer.close()

            result.toList.writeToCsvFile(dst)
        } finally {
            source.close()
        }
    }
}

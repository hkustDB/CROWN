package experiments.data.convert.dbtoastercpp

import experiments.data.convert.Convertor
import experiments.data.utils.CsvFileWriter.createCsvFileWriterForList

import java.io.{BufferedWriter, FileOutputStream, OutputStreamWriter}
import scala.collection.mutable.{ArrayBuffer, ListBuffer}
import scala.io.Source

object DataConvertor extends Convertor {
    override def convert(args: Array[String]): Unit = {
        val src = args(0)
        val dst = args(1)

        // insert '*' row to indicate a full enum only when insertEnumRow is set
        // set this flag only to one of the copy when you have more than 1 stream reading the same
        // original input file
        val insertEnumRow = (args.length > 2 && args(2) == "insertEnumRow")

        val source = Source.fromFile(src)
        try {
            var cnt = 0
            val lines = source.getLines().toList
            val result = ListBuffer.empty[Array[String]]
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
                } else if (strings.head == "*" && insertEnumRow) {
                    // encounter a line begin with "*", trigger full enum
                    val buffer = new ArrayBuffer[String](2)
                    buffer.addOne(cnt.toString)
                    buffer.addOne("-1")
                    result.addOne(buffer.toArray)
                } else {
                    // unknown op
                }
            })
            result.toList.writeToCsvFile(dst)
        } finally {
            source.close()
        }
    }
}

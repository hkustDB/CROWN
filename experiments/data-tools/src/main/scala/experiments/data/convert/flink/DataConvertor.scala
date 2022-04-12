package experiments.data.convert.flink

import experiments.data.convert.Convertor
import experiments.data.utils.CsvFileWriter._

import java.text.SimpleDateFormat
import java.util.Date
import scala.collection.mutable.ArrayBuffer
import scala.io.Source


object DataConvertor extends Convertor {
    override def convert(args: Array[String]): Unit = {
        val src = args(0)
        val dst = args(1)
        println("convert from " + src + " to " + dst)

        var time = 0
        val date = new Date(0)
        val format = "yyyy-MM-dd HH:mm:ss.SSS"
        val dateFormat = new SimpleDateFormat(format)
        val source = Source.fromFile(src)
        try {
            val lines = source.getLines().toList
            val result = lines.map(line => {
                val strings = line.split(",")
                val buffer = new ArrayBuffer[String](strings.length + 1)
                buffer.addAll(strings)

                println("add" + strings.mkString(","))

                date.setTime(time)
                time = time + 1000
                buffer.addOne(dateFormat.format(date))
                buffer.toArray
            })
            result.writeToCsvFile(dst)
        } finally {
            source.close()
        }
    }
}

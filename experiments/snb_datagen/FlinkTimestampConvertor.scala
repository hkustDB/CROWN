import java.io.{BufferedWriter, FileOutputStream, OutputStreamWriter}
import java.text.SimpleDateFormat
import java.util.Date
import scala.io.Source
import scala.util.Random

object FlinkTimestampConvertor {
    def main(args: Array[String]): Unit = {

        val from = args(0)
        val to = args(1)


        val writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(to)))
        val format = "yyyy-MM-dd HH:mm:ss.SSS"
        val dateFormat = new SimpleDateFormat(format)

        val src = Source.fromFile(from)
        src.getLines().foreach(line => {
            val strs = line.split("\\|")
            val ts = strs.head.toLong
            val d = new Date(ts)
            writer.write(dateFormat.format(d) + "|" + strs.tail.mkString("|"))
            writer.newLine()
        })

        src.close()

        writer.flush()
        writer.close()
    }

}
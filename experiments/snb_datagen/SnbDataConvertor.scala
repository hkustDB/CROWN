import java.io.{BufferedReader, BufferedWriter, FileInputStream, FileOutputStream, InputStreamReader, OutputStreamWriter}
import java.util.Date
import scala.collection.mutable

/**
 * convert raw snb data to readable format for acq, dyn, dbtoaster
 */
object SnbDataConvertor {
    def main(args: Array[String]) = {
        val basePath = args(0)      // path to the raw files
        val fileList = args(1).split(",").filter(_.nonEmpty).toList
        val windowSize = args(2).toInt      // 180 days
        // trigger full enum every half window size
        val emitSize = windowSize / 2

        val dbtSparkBatchSize = args(3).toInt
        val outputPath = args(4)
        val mode = args(5) // window or arbitrary

        var enumBuffer: String = ""

        val sizeInSeconds = emitSize * 24 * 60 * 60
        val readersAndTag = fileList.map(fileName => {
            val file = basePath + "/" + fileName
            (new BufferedReader(new InputStreamReader(new FileInputStream(file))), fileName)
        })

        val heap = mutable.PriorityQueue.empty[(Long, String, Array[String], BufferedReader)](
            Ordering.by((_: (Long, String, Array[String], BufferedReader))._1).reverse
        )

        readersAndTag.foreach(t => {
            val reader = t._1
            val tag = t._2
            val line = reader.readLine()
            val array = line.split("\\|")
            val timestamp = array.head.toLong
            heap.enqueue((timestamp, tag, array, reader))
        })

        val allInOneWriter = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(outputPath + "/data.csv")))
        val dbtoasterCppWriters = fileList.map(fileName => (fileName, new BufferedWriter(new OutputStreamWriter(new FileOutputStream(outputPath + "/dbtoaster_cpp." + fileName +"." + mode +".csv"))))).toMap
        val dbtoasterSparkWriters = fileList.map(fileName => (fileName, new BufferedWriter(new OutputStreamWriter(new FileOutputStream(outputPath + "/dbtoaster." + fileName +"." + mode +".csv"))))).toMap
        val enumPointsWriter = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(outputPath + "/enum-points-perf.txt")))

        val tagShortNames=Map("knows"->"KN","message"->"ME", "person"->"PE","messagetag"->"MT","tag"->"TA", "knows1"->"KN")

        var lastEmitDate = new Date(0)
        var lastHalfWindowIndex = heap.head._1 / sizeInSeconds
        var cnt = 0
        while (heap.head._1 < Long.MaxValue) {
            val (ts, tag, array, reader) = heap.dequeue()
            cnt += 1

            val newHalfWindowIndex = ts / sizeInSeconds
            if (newHalfWindowIndex != lastHalfWindowIndex) {
                println("last emit date = " + lastEmitDate)
                lastEmitDate = new Date((ts * 1000))
                println("insert * in " + tag + " now = " + lastEmitDate)

                // for acq and dyn
                lastHalfWindowIndex = newHalfWindowIndex
                allInOneWriter.write("*")
                allInOneWriter.newLine()

                // for dbtoaster cpp
                dbtoasterCppWriters(tag).write(ts + "|" + "-1")
                dbtoasterCppWriters(tag).newLine()

                // for dbtoaster spark
                val enumBatchNum = cnt / dbtSparkBatchSize
                if (enumBuffer != "")
                    enumBuffer += ","
                enumBuffer += enumBatchNum.toString
            }

            if (tag == "tag") {
                allInOneWriter.write("+|" + tagShortNames(tag) + "|" + array.slice(1, array.length).mkString("|"))
                allInOneWriter.newLine()

                dbtoasterCppWriters(tag).write(array(0) + "|1|" + array.slice(1, array.length).mkString("|"))
                dbtoasterCppWriters(tag).newLine()

                dbtoasterSparkWriters(tag).write(array(0) + "|1|" + array.slice(1, array.length).mkString("|"))
                dbtoasterSparkWriters(tag).newLine()
            } else {
                if (!tag.endsWith("2")) {
                    // write only one copy to allinone
                    val op = array(1).toInt
                    allInOneWriter.write((if (op == 1) "+" else "-") + "|" + tagShortNames(tag) + "|" + array.slice(2, array.length).mkString("|"))
                    allInOneWriter.newLine()
                }

                dbtoasterCppWriters(tag).write(array.mkString("|"))
                dbtoasterCppWriters(tag).newLine()

                dbtoasterSparkWriters(tag).write(array.mkString("|"))
                dbtoasterSparkWriters(tag).newLine()
            }

            val line = reader.readLine()
            val arr = if (line == null) Array[String]() else line.split("\\|")
            val timestamp = if (line == null) Long.MaxValue else arr.head.toLong
            heap.enqueue((timestamp, tag, arr, reader))
        }

        allInOneWriter.flush()
        allInOneWriter.close()

        enumPointsWriter.write(enumBuffer)
        enumPointsWriter.flush()
        enumPointsWriter.close()

        dbtoasterCppWriters.values.foreach(w => {
            w.flush()
            w.close()
        })

        dbtoasterSparkWriters.values.foreach(w => {
            w.flush()
            w.close()
        })
    }
}

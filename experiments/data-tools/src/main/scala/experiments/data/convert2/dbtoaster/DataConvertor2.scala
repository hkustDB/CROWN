package experiments.data.convert2.dbtoaster

import experiments.data.convert2.Convertor2
import experiments.data.utils.CsvFileWriter.createCsvFileWriterForList

import java.io.{BufferedWriter, FileOutputStream, OutputStreamWriter}
import scala.collection.mutable
import scala.collection.mutable.{ArrayBuffer, ListBuffer}
import scala.io.Source

object DataConvertor2 extends Convertor2 {
    override def convert2(args: Array[String]): Unit = {
        val src = args(0)
        val dst = args(1)
        val windowSmallFactor = args(2).toDouble
        // data.csv
        val smallStreamName = args(3)
        val windowBigFactor = args(4).toDouble
        // data2.csv
        val bigStreamName = args(5)
        val batchSize = args(6).toInt
        val smallLineCountMultiplier = args(7).toInt

        val enumFactor = 0.1

        val source = Source.fromFile(src)
        try {
            val lines = source.getLines().toList
            val windowSmallSize = (windowSmallFactor * lines.size).toInt
            val windowBigSize = (windowBigFactor * lines.size).toInt
            val enumStep = (enumFactor * lines.size).toInt
            var nextEnumPoint = enumStep

            var current = 0
            var currentTupleIndex = 0
            val arrayBuffer = new ArrayBuffer[String]()
            val bufferSmall = ListBuffer.empty[Array[String]]
            val bufferBig = ListBuffer.empty[Array[String]]
            val deleteQueueSmall = mutable.Queue.empty[Array[String]]
            val deleteQueueBig = mutable.Queue.empty[Array[String]]
            var enumPoints = ""

            lines.foreach(line => {
                val fields = line.split(",")

                current += 1

                // delete elements in small streams outside the window
                if (current > windowSmallSize) {
                    val array = deleteQueueSmall.dequeue()
                    array(0) = current.toString
                    bufferSmall.addOne(array)
                    currentTupleIndex += smallLineCountMultiplier
                }

                // delete elements in big streams outside the window
                if (current > windowBigSize) {
                    val array = deleteQueueBig.dequeue()
                    array(0) = current.toString
                    bufferBig.addOne(array)
                    currentTupleIndex += 1
                }

                arrayBuffer.clear()
                arrayBuffer.addOne(current.toString)
                arrayBuffer.addOne("1")
                arrayBuffer.addAll(fields)

                bufferSmall.addOne(arrayBuffer.toArray)
                currentTupleIndex += smallLineCountMultiplier
                bufferBig.addOne(arrayBuffer.toArray)
                currentTupleIndex += 1

                arrayBuffer(1) = "0"
                deleteQueueSmall.enqueue(arrayBuffer.toArray)
                deleteQueueBig.enqueue(arrayBuffer.toArray)

                // check whether or not to insert a * row
                if (current > nextEnumPoint) {
                    nextEnumPoint += enumStep
                    if (enumPoints.nonEmpty)
                        enumPoints += ","
                    enumPoints += (currentTupleIndex / batchSize).toString
                }
            })

            var cnt = current
            while (deleteQueueSmall.nonEmpty) {
                cnt += 1
                val array = deleteQueueSmall.dequeue()
                array(0) = cnt.toString
                bufferSmall.addOne(array)
            }

            cnt = current
            while (deleteQueueBig.nonEmpty) {
                cnt += 1
                val array = deleteQueueBig.dequeue()
                array(0) = cnt.toString
                bufferBig.addOne(array)
            }

            bufferBig.toList.writeToCsvFile(dst + "/" + bigStreamName)
            bufferSmall.toList.writeToCsvFile(dst + "/" + smallStreamName)

            val writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(dst + "/" + "enum-points-perf.txt")))
            writer.write(enumPoints)
            writer.flush()
            writer.close()

        } finally {
            source.close()
        }
    }
}

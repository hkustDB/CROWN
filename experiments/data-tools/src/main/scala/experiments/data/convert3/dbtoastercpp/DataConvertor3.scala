package experiments.data.convert3.dbtoastercpp

import experiments.data.convert2.Convertor2
import experiments.data.convert3.Convertor3
import experiments.data.utils.CsvFileWriter.createCsvFileWriterForList

import scala.collection.mutable
import scala.collection.mutable.{ArrayBuffer, ListBuffer}
import scala.io.Source

object DataConvertor3 extends Convertor3 {
    override def convert3(args: Array[String]): Unit = {
        val src = args(0)
        val dst = args(1)
        // data1.csv
        val smallStreamName = args(2)
        val windowBigFactor = args(3).toDouble
        // data2.csv
        val bigStreamName = args(4)

        val source = Source.fromFile(src)
        try {
            val lines = source.getLines().toList
            val windowBigSize = (windowBigFactor * lines.size).toInt

            var current = 0
            var currentBig = 0
            val arrayBuffer = new ArrayBuffer[String]()
            val bufferSmall = ListBuffer.empty[Array[String]]
            val bufferBig = ListBuffer.empty[Array[String]]
            val deleteQueueBig = mutable.Queue.empty[Array[String]]

            var it = lines.iterator
            var isSmallStreamsInserting = true

            lines.foreach(line => {
                currentBig += 1
                val fields = line.split(",")

                for (_ <- (0 until 20)) {
                    current += 1
                    if (!it.hasNext) {
                        isSmallStreamsInserting = !isSmallStreamsInserting
                        it = lines.iterator
                    }

                    arrayBuffer.clear()
                    arrayBuffer.addOne(current.toString)
                    if (isSmallStreamsInserting)
                        arrayBuffer.addOne("1")
                    else
                        arrayBuffer.addOne("0")
                    arrayBuffer.addAll(it.next().split(","))
                    bufferSmall.addOne(arrayBuffer.toArray)
                }

                // delete elements in big streams outside the window
                if (currentBig > windowBigSize) {
                    val array = deleteQueueBig.dequeue()
                    array(0) = current.toString
                    bufferBig.addOne(array)
                }

                arrayBuffer.clear()
                arrayBuffer.addOne(current.toString)
                arrayBuffer.addOne("1")
                arrayBuffer.addAll(fields)
                bufferBig.addOne(arrayBuffer.toArray)

                arrayBuffer(1) = "0"
                deleteQueueBig.enqueue(arrayBuffer.toArray)
            })

            while (deleteQueueBig.nonEmpty) {
                for (_ <- (0 until 20)) {
                    current += 1
                    if (!it.hasNext) {
                        isSmallStreamsInserting = !isSmallStreamsInserting
                        it = lines.iterator
                    }

                    arrayBuffer.clear()
                    arrayBuffer.addOne(current.toString)
                    if (isSmallStreamsInserting)
                        arrayBuffer.addOne("1")
                    else
                        arrayBuffer.addOne("0")
                    arrayBuffer.addAll(it.next().split(","))
                    bufferSmall.addOne(arrayBuffer.toArray)
                }

                val array = deleteQueueBig.dequeue()
                array(0) = current.toString
                bufferBig.addOne(array)
            }

            bufferBig.toList.writeToCsvFile(dst + "/" + bigStreamName)
            bufferSmall.toList.writeToCsvFile(dst + "/" + smallStreamName)
        } finally {
            source.close()
        }
    }
}

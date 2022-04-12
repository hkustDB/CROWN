package experiments.data.convert2.acq

import experiments.data.convert2.Convertor2
import experiments.data.utils.CsvFileWriter.createCsvFileWriterForList

import scala.collection.mutable
import scala.collection.mutable.{ArrayBuffer, ListBuffer}
import scala.io.Source

object DataConvertor2 extends Convertor2 {
    override def convert2(args: Array[String]): Unit = {
        val src = args(0)
        val dst = args(1)
        val windowSmallFactor = args(2).toDouble
        // G1,G3
        val smallStreamNames = args(3).split(",").map(_.trim).toList
        val windowBigFactor = args(4).toDouble
        // G2
        val bigStreamNames = args(5).split(",").map(_.trim).toList
        val allNames = smallStreamNames ++ bigStreamNames

        val enumFactor = 0.1

        val source = Source.fromFile(src)
        try {
            val lines = source.getLines().toList
            val windowSmallSize = (windowSmallFactor * lines.size).toInt
            val windowBigSize = (windowBigFactor * lines.size).toInt
            val enumStep = (enumFactor * lines.size).toInt
            var nextEnumPoint = enumStep

            var current = 0
            val arrayBuffer = new ArrayBuffer[String]()
            val buffer = ListBuffer.empty[Array[String]]
            val deleteQueues = allNames.map(name => (name, mutable.Queue.empty[Array[String]])).toMap

            lines.foreach(line => {
                val fields = line.split(",")

                current += 1

                // delete elements in small streams outside the window
                if (current > windowSmallSize) {
                    smallStreamNames.foreach(n => {
                        val queue = deleteQueues(n)
                        buffer.addOne(queue.dequeue())
                    })
                }

                // delete elements in big streams outside the window
                if (current > windowBigSize) {
                    bigStreamNames.foreach(n => {
                        val queue = deleteQueues(n)
                        buffer.addOne(queue.dequeue())
                    })
                }

                // add elements to buffer and deleteQueues for future deletion
                allNames.foreach(n => {
                    val queue = deleteQueues(n)
                    arrayBuffer.clear()
                    arrayBuffer.addOne("+")
                    arrayBuffer.addOne(n)
                    arrayBuffer.addAll(fields)
                    buffer.addOne(arrayBuffer.toArray)

                    arrayBuffer(0) = "-"
                    queue.enqueue(arrayBuffer.toArray)
                })

                // check whether or not to insert a * row
                if (current > nextEnumPoint) {
                    nextEnumPoint += enumStep
                    buffer.addOne(Array("*"))
                }
            })

            // delete the elements remain in deleteQueues
            deleteQueues.values.foreach(queue => {
                while (queue.nonEmpty) {
                    buffer.addOne(queue.dequeue())
                }
            })

            // write to dst
            buffer.toList.writeToCsvFile(dst)
        } finally {
            source.close()
        }
    }
}

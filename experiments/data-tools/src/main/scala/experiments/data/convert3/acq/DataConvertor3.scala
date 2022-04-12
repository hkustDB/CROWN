package experiments.data.convert3.acq

import experiments.data.convert3.Convertor3

import java.io.{BufferedWriter, FileOutputStream, OutputStreamWriter}
import scala.collection.mutable
import scala.collection.mutable.ArrayBuffer
import scala.io.Source

object DataConvertor3 extends Convertor3 {
    override def convert3(args: Array[String]): Unit = {
        val src = args(0)
        val dst = args(1)
        // G1,G3
        val smallStreamNames = args(2).split(",").map(_.trim).toList
        val windowBigFactor = args(3).toDouble
        // G2
        val bigStreamNames = args(4).split(",").map(_.trim).toList

        val queue = mutable.Queue.empty[Array[String]]
        val writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(dst)))

        val source = Source.fromFile(src)
        try {
            val lines = source.getLines().toList
            val windowBigSize = (windowBigFactor * lines.size).toInt

            var isSmallStreamsInserting = true

            var current = 0
            val arrayBuffer = new ArrayBuffer[String]()

            var it = lines.iterator

            lines.foreach(line => {
                val fields = line.split(",")

                current += 1

                for (_ <- (0 until 20)) {
                    if (!it.hasNext) {
                        isSmallStreamsInserting = !isSmallStreamsInserting
                        it = lines.iterator
                    }

                    arrayBuffer.clear()
                    if (isSmallStreamsInserting)
                        arrayBuffer.addOne("+")
                    else
                        arrayBuffer.addOne("-")

                    arrayBuffer.addOne("")
                    arrayBuffer.addAll(it.next().split(","))

                    smallStreamNames.foreach(n => {
                        arrayBuffer(1) = n
                        writer.write(arrayBuffer.mkString(","))
                        writer.newLine()
                    })
                }

                // delete elements in big streams outside the window
                if (current > windowBigSize) {
                    writer.write(queue.dequeue().mkString(","))
                    writer.newLine()
                }

                arrayBuffer.clear()
                arrayBuffer.addOne("+")
                arrayBuffer.addOne(bigStreamNames.head)
                arrayBuffer.addAll(fields)
                writer.write(arrayBuffer.mkString(","))
                writer.newLine()

                arrayBuffer(0) = "-"
                queue.enqueue(arrayBuffer.toArray)
            })

            // delete the elements remain in deleteQueues
            while (queue.nonEmpty) {
                for (_ <- (0 until 20)) {
                    if (!it.hasNext) {
                        isSmallStreamsInserting = !isSmallStreamsInserting
                        it = lines.iterator
                    }

                    arrayBuffer.clear()
                    if (isSmallStreamsInserting)
                        arrayBuffer.addOne("+")
                    else
                        arrayBuffer.addOne("-")

                    arrayBuffer.addOne("")
                    arrayBuffer.addAll(it.next().split(","))

                    smallStreamNames.foreach(n => {
                        arrayBuffer(1) = n
                        writer.write(arrayBuffer.mkString(","))
                        writer.newLine()
                    })
                }
                writer.write(queue.dequeue().mkString(","))
                writer.newLine()
            }

            writer.flush()
            writer.close()
        } finally {
            source.close()
        }
    }
}

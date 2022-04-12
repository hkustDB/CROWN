package experiments.data.preprocess

import experiments.data.utils.CsvFileWriter.createCsvFileWriterForList

import scala.collection.mutable
import scala.collection.mutable.{ArrayBuffer, ListBuffer}
import scala.io.Source

/**
 * convert a normal input file to windowed file
 * a line with only a star is inserted every half window size, to indicate that
 * a full enum should be triggered here.
 * note that 'every half window size' is counted in the original file,
 * so actually we insert a * line after (windowSize/2) line is added with '+'.
 *
 * for example, a file with the following content
 * 1,2,3
 * 2,3,4
 * 3,4,5
 * ...
 * (10 lines)
 *
 * will be converted(with windowSizeFactor = 0.2, means windowSize = 2) to
 * +,1,2,3
 * * // full enum
 * +,2,3,4
 * * // full enum
 * -,1,2,3
 * +,3,4,5
 * * // full enum
 * -,2,3,4
 * ...
 * (20 lines)
 */
object CountWindowPreprocessor {
    def process(args: Array[String]): Unit = {
        val src = args(0)
        val dst = args(1)
        val windowSizeFactor = args(2).toDouble

        var cnt = 1
        // outer list buffer
        val buffer = ListBuffer.empty[Array[String]]
        // queue for rows to be deleted
        val deleteQueue = mutable.Queue.empty[Array[String]]
        // reuse array buffer
        val arrayBuffer = new ArrayBuffer[String]()
        var insertedLinesSinceLastStar = 0
        val source = Source.fromFile(src)
        try {
            val lines = source.getLines().toList
            var windowSize = (windowSizeFactor * lines.length).toInt
            // handle case that the calculated windowSize is odd
            if (windowSize % 2 == 1)
                windowSize = windowSize + 1
            val halfWindowSize = windowSize / 2

            lines.foreach(line => {
                if (cnt > windowSize)
                    buffer.addOne(deleteQueue.dequeue())
                cnt += 1
                val strings = line.split(",")
                arrayBuffer.clear()
                arrayBuffer.addOne("+")
                arrayBuffer.addAll(strings)
                buffer.addOne(arrayBuffer.toArray)
                insertedLinesSinceLastStar += 1
                if (insertedLinesSinceLastStar == halfWindowSize) {
                    buffer.addOne(Array[String]("*"))
                    insertedLinesSinceLastStar = 0
                }

                arrayBuffer(0) = "-"
                deleteQueue.enqueue(arrayBuffer.toArray)
            })

            // this happens when line count of input is not n times of windowSize
            // for example, if line count = 99, factor = 0.2,
            // then windowSize = 20, halfWindowSize = 10,
            // when we meet the last row of input, insertedLinesSinceLastStar = 9
            // so we need to explicitly add a * row.
            if (buffer.last.head != "*")
                buffer.addOne(Array[String]("*"))

            while (deleteQueue.nonEmpty)
                buffer.addOne(deleteQueue.dequeue())

            buffer.toList.writeToCsvFile(dst)
        } finally {
            source.close()
        }
    }
}

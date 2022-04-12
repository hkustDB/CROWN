package experiments.data.preprocess

import experiments.data.utils.CsvFileWriter.createCsvFileWriterForList

import scala.collection.mutable
import scala.collection.mutable.{ArrayBuffer, ListBuffer}
import scala.io.Source

/**
 * convert the generated input file to file with insert and delete
 * all lines will be added as insertion,
 * then the first half will be added as deletion.
 *
 * This rule insures that the test input will always contains both insert and delete.
 * Also, there will be about half of the original input remains till the end.
 * So the full enum at the end won't return empty result.
 *
 * for example, a file with the following content
 * 1,2,3
 * 2,3,4
 * 3,4,5
 * ...
 * (10 lines)
 *
 * will be converted to
 * +,1,2,3
 * +,2,3,4
 * +,3,4,5
 * ... other insertions
 * +,10,11,12 (end of insertions)
 * -,1,2,3
 * -,2,3,4
 * ...
 * -,5,6,7 (end of deletions)
 */
object FuncTestPreprocessor {
    def process(args: Array[String]): Unit = {
        val src = args(0)
        val dst = args(1)

        // outer list buffer
        val buffer = ListBuffer.empty[Array[String]]
        // reuse array buffer
        val arrayBuffer = new ArrayBuffer[String]()
        var insertedLinesSinceLastStar = 0
        val source = Source.fromFile(src)
        try {
            val lines = source.getLines().toList
            val totalCount = lines.size

            // insertions
            lines.foreach(line => {
                val strings = line.split(",")
                arrayBuffer.clear()
                arrayBuffer.addOne("+")
                arrayBuffer.addAll(strings)
                buffer.addOne(arrayBuffer.toArray)
            })

            // deletions
            lines.take(lines.size / 2).foreach(line => {
                val strings = line.split(",")
                arrayBuffer.clear()
                arrayBuffer.addOne("-")
                arrayBuffer.addAll(strings)
                buffer.addOne(arrayBuffer.toArray)
            })



            buffer.toList.writeToCsvFile(dst)
        } finally {
            source.close()
        }
    }
}

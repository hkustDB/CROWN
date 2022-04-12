package experiments.data.utils

import com.opencsv.CSVWriterBuilder

import java.io.{BufferedWriter, FileWriter}
import scala.collection.immutable.AbstractSeq

class CsvFileWriter[T](stream: AbstractSeq[T]) {
    def writeToCsvFile(path: String)(implicit convert: T => Array[String]): Unit = {
        val builder = new CSVWriterBuilder(new BufferedWriter(new FileWriter(path)))
        val writer = builder.withQuoteChar('\u0000').build()
        stream.foreach(t => writer.writeNext(convert(t)))
        writer.close()
    }
}

object CsvFileWriter {
    implicit def createCsvFileWriterForLazyList[T](lazyList: LazyList[T]): CsvFileWriter[T] =
        new CsvFileWriter[T](lazyList)

    implicit def createCsvFileWriterForList[T](list: List[T]): CsvFileWriter[T] =
        new CsvFileWriter[T](list)
}

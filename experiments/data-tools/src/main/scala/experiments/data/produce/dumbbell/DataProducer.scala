package experiments.data.produce.dumbbell

import experiments.data.produce.Producer
import experiments.data.utils.CsvFileWriter._
import experiments.data.utils.DynamicGraphGenerator
import experiments.data.utils.Extensions._

object DataProducer extends Producer {
    def produce(args: Array[String]): Unit = {
        val path = args.head
        args(1) match {
            case "func" =>
                produceFunc(path)
            case _ => throw new RuntimeException("should provide 'func'")
        }
    }

    def produceFunc(path: String) = {
        DynamicGraphGenerator
            .generate(100, 200)
            .writeToCsvFile(s"$path/func/data.raw")
    }
}

package experiments.data.produce

trait Producer {
    def produce(args: Array[String]): Unit
}

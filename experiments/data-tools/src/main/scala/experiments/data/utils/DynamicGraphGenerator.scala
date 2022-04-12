package experiments.data.utils

import scala.collection.mutable.ListBuffer
import scala.util.Random

object DynamicGraphGenerator {
    def generate(nodesCount: Int, linesCount: Int): List[(Int, Int)] = {
        assert(nodesCount > 0)
        assert(nodesCount * (nodesCount - 1) / 2 > linesCount)
        assert(linesCount > 0)

        val buffer = ListBuffer.empty[(Int, Int)]
        for (src <- (0 until (nodesCount - 1))) {
            for (dst <- ((src + 1) until nodesCount)) {
                buffer.addOne((src, dst))
            }
        }

        Random.shuffle(buffer.toList).take(linesCount)
    }
}

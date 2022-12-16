import java.io.{BufferedReader, BufferedWriter, FileInputStream, FileOutputStream, InputStreamReader, OutputStreamWriter}
import java.text.SimpleDateFormat
import java.util.{Date, TimeZone}
import scala.collection.mutable
import scala.collection.mutable.ListBuffer
import scala.util.Random

/**
 * For crown/toaster, ensure the ratio of v1/v2 rows to the graph rows is around K/M.
 * For flink/trill, output a row when crown add an insertion. Set the window size to the count of elements
 * when the first deletion in crown happens.
 */
object Convert2Comb {
    def main(args: Array[String]): Unit = {
        val src = args(0)
        val dst = args(1)
        val rows = args(2).toInt
        val windowFactor = 0.2    // window size = 0.2N, N=rows, window step = (window size)/2
        val v1v2Factor = 0.2      // insert 0.2K vertices to V1/V2, K=count(distinct src/dst)

        val reader = new BufferedReader(new InputStreamReader(new FileInputStream(src)))

        // for crown
        val crown_writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(s"${dst}/crown.data.csv")))
        // for dbtoaster cpp
        val writer_cpp_graphes = Array.fill(3)(null.asInstanceOf[BufferedWriter])
        writer_cpp_graphes(0) = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(s"${dst}/dbtoaster_cpp.graph1.csv")))
        writer_cpp_graphes(1) = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(s"${dst}/dbtoaster_cpp.graph2.csv")))
        writer_cpp_graphes(2) = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(s"${dst}/dbtoaster_cpp.graph3.csv")))
        val writer_cpp_v1 = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(s"${dst}/dbtoaster_cpp.v1.csv")))
        val writer_cpp_v2 = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(s"${dst}/dbtoaster_cpp.v2.csv")))
        // for flink
        val writer_flink_graph = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(s"${dst}/flink.graph.csv")))
        val writer_flink_v1 = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(s"${dst}/flink.v1.csv")))
        val writer_flink_v2 = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(s"${dst}/flink.v2.csv")))
        // for trill(same as flink, except ts = flink_ts/1000, in seconds)
        val writer_trill_graph = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(s"${dst}/trill.graph.csv")))
        val writer_trill_v1 = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(s"${dst}/trill.v1.csv")))
        val writer_trill_v2 = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(s"${dst}/trill.v2.csv")))

        // read
        val list = ListBuffer.empty[(Int, Int)]
        var line = reader.readLine()
        while (line != null) {
            val splited = line.split(",")
            list.append((splited(0).toInt, splited(1).toInt))
            line = reader.readLine()
        }

        // deduplicate src and dst
        val srcSet = list.map(t => t._1).toSet
        val dstSet = list.map(t => t._2).toSet
        val distinctSrcs = srcSet.size
        val distinctDsts = dstSet.size
        println(s"distinct A = ${distinctSrcs}")
        println(s"distinct D = ${distinctDsts}")

        // windowSize only counts graph tuples
        val windowStep = Math.ceil(rows * (windowFactor / 2)).toInt + 1
        val windowSize = windowStep * 2

        // in each window, there are ${distinctSrcs.toDouble*v1v2Factor} v1 rows, and ${windowSize} graph rpws
        // this ratio should be enforced in any interval of the input file
        val srcRatio = (distinctSrcs.toDouble*v1v2Factor) / windowSize
        val dstRatio = (distinctDsts.toDouble*v1v2Factor) / windowSize

        println(s"rows = ${rows}, windowSize=${windowSize}, windowStep=${windowStep}")

        var dbtoaster_ts = 1

        var flink_ts = 0L
        val date = new Date(0)
        val format = "yyyy-MM-dd HH:mm:ss.SSS"
        val dateFormat = new SimpleDateFormat(format)
        dateFormat.setTimeZone(TimeZone.getTimeZone("UTC"))
        var isFlinkWindowPrinted = false

        def insertEnumStar(): Unit = {
            crown_writer.write("*\n")
            writer_cpp_graphes(2).write(s"${dbtoaster_ts}|-1\n")
            dbtoaster_ts+=1
        }

        var current = 0
        var nextEnumPoint = windowStep
        val graphQueue = mutable.Queue.empty[(Int, (Int, Int))]
        val v1Queue = mutable.Queue.empty[(Int, Int)]
        val v2Queue = mutable.Queue.empty[(Int, Int)]

        def pickRandomV1(): Int = {
            val candidate = (srcSet -- v1Queue.map(_._2)).toList
            Random.shuffle(candidate).head
        }

        def pickRandomV2(): Int = {
            val candidate = (dstSet -- v2Queue.map(_._2)).toList
            Random.shuffle(candidate).head
        }

        list.foreach(tuple => {
            current += 1
            graphQueue.enqueue((current, tuple))
            crown_writer.write(s"+,G,${tuple._1},${tuple._2}\n")
            for (i <- (0 until 3)) {
                writer_cpp_graphes(i).write(s"${dbtoaster_ts}|1|${tuple._1}|${tuple._2}\n")
                dbtoaster_ts+=1
            }
            flink_ts+=1000
            date.setTime(flink_ts)
            writer_flink_graph.write(s"${tuple._1}|${tuple._2}|${dateFormat.format(date)}\n")
            writer_trill_graph.write(s"${flink_ts/1000},${tuple._1},${tuple._2}\n")

            // whether to insert v1
            if ((v1Queue.size.toDouble / graphQueue.size) < srcRatio) {
                val v1 = pickRandomV1()
                v1Queue.enqueue((current, v1))
                crown_writer.write(s"+,V1,${v1}\n")

                writer_cpp_v1.write(s"${dbtoaster_ts}|1|${v1}\n")
                dbtoaster_ts+=1

                flink_ts+=1000
                date.setTime(flink_ts)
                writer_flink_v1.write(s"${v1}|${dateFormat.format(date)}\n")
                writer_trill_v1.write(s"${flink_ts/1000},${v1}\n")
            }

            // whether to insert v2
            if ((v2Queue.size.toDouble / graphQueue.size) < dstRatio) {
                val v2 = pickRandomV2()
                v2Queue.enqueue((current, v2))
                crown_writer.write(s"+,V2,${v2}\n")

                writer_cpp_v2.write(s"${dbtoaster_ts}|1|${v2}\n")
                dbtoaster_ts+=1

                flink_ts+=1000
                date.setTime(flink_ts)
                writer_flink_v2.write(s"${v2}|${dateFormat.format(date)}\n")
                writer_trill_v2.write(s"${flink_ts/1000},${v2}\n")
            }

            if (current > windowSize) {
                // delete the expired element
                val head = graphQueue.dequeue()
                // whether to remove v1
                if (v1Queue.head._1 < head._1) {
                    val v1h = v1Queue.dequeue()
                    crown_writer.write(s"-,V1,${v1h._2}\n")
                    writer_cpp_v1.write(s"${dbtoaster_ts}|1|${v1h._2}\n")
                    dbtoaster_ts+=1
                }
                // whether to remove v2
                if (v2Queue.head._1 < head._1) {
                    val v2h = v2Queue.dequeue()
                    crown_writer.write(s"-,V2,${v2h._2}\n")
                    writer_cpp_v2.write(s"${dbtoaster_ts}|1|${v2h._2}\n")
                    dbtoaster_ts+=1
                }

                crown_writer.write(s"-,G,${head._2._1},${head._2._2}\n")
                for (i <- (0 until 3)) {
                    writer_cpp_graphes(i).write(s"${dbtoaster_ts}|0|${head._2._1}|${head._2._2}\n")
                    dbtoaster_ts+=1
                }

                if (!isFlinkWindowPrinted) {
                    isFlinkWindowPrinted = true
                    date.setTime(flink_ts)
                    println(s"flink window size = ${flink_ts}, first window end at ${dateFormat.format(date)}")
                }
            }

            if (current > nextEnumPoint) {
                insertEnumStar()
                nextEnumPoint += windowStep
            }
        })

        insertEnumStar()
        while (graphQueue.nonEmpty) {
            // delete the remaining tuples
            // should be useless since no
            val head = graphQueue.dequeue()
            // whether to remove v1
            if (v1Queue.nonEmpty && v1Queue.head._1 < head._1) {
                val v1h = v1Queue.dequeue()
                crown_writer.write(s"-,V1,${v1h._2}\n")
                writer_cpp_v1.write(s"${dbtoaster_ts}|1|${v1h._2}\n")
                dbtoaster_ts+=1
            }
            // whether to remove v2
            if (v2Queue.nonEmpty && v2Queue.head._1 < head._1) {
                val v2h = v2Queue.dequeue()
                crown_writer.write(s"-,V2,${v2h._2}\n")
                writer_cpp_v2.write(s"${dbtoaster_ts}|1|${v2h._2}\n")
                dbtoaster_ts+=1
            }

            crown_writer.write(s"-,G,${head._2._1},${head._2._2}\n")
            for (i <- (0 until 3)) {
                writer_cpp_graphes(i).write(s"${dbtoaster_ts}|0|${head._2._1}|${head._2._2}\n")
                dbtoaster_ts+=1
            }
        }

        crown_writer.flush()
        crown_writer.close()

        for (i <- (0 until 3)) {
            writer_cpp_graphes(i).flush()
            writer_cpp_graphes(i).close()
        }
        writer_cpp_v1.flush()
        writer_cpp_v1.close()
        writer_cpp_v2.flush()
        writer_cpp_v2.close()

        writer_flink_graph.flush()
        writer_flink_graph.close()
        writer_flink_v1.flush()
        writer_flink_v1.close()
        writer_flink_v2.flush()
        writer_flink_v2.close()

        writer_trill_graph.flush()
        writer_trill_graph.close()
        writer_trill_v1.flush()
        writer_trill_v1.close()
        writer_trill_v2.flush()
        writer_trill_v2.close()
    }
}
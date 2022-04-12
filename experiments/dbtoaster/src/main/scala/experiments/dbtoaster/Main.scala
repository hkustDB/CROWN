package experiments.dbtoaster

import ddbt.lib.Helper.ExperimentHelperListener
import ddbt.lib.M3Map

import java.io.{BufferedWriter, FileOutputStream, OutputStreamWriter}
import scala.reflect.runtime.universe

object Main {
    def main(args: Array[String]): Unit = {
        if (args.length < 2) {
            printUsage()
        } else {
            val experimentName = args.head
            val executionTimeLog = args(1)
            val queryArgs = args.drop(2)

            val dummy = new ExperimentHelperListener {
                override def onSnapshot(snapshot: List[Any]): Unit = {}

                override def onExecutionTime(time: Double): Unit = {
                    val writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(executionTimeLog)))
                    writer.write((time / 1000f).formatted("%.2f"))
                    writer.flush()
                    writer.close()
                }
            }

            val query = getObjectAs[Executable](s"experiments.dbtoaster.$experimentName.Query")
            query.exec(queryArgs, dummy)
        }
    }

    def getObjectAs[T](name: String): T = {
        val runtimeMirror = universe.runtimeMirror(getClass.getClassLoader)
        val module = runtimeMirror.staticModule(name)
        val obj = runtimeMirror.reflectModule(module)
        obj.instance.asInstanceOf[T]
    }

    def printUsage(): Unit = {
        println("experiments-dbtoaster experimentName executionTimeLog [args]")
        System.exit(1)
    }
}

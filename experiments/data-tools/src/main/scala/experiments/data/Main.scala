package experiments.data

import experiments.data.convert.Convertor
import experiments.data.convert2.Convertor2
import experiments.data.convert3.Convertor3
import experiments.data.produce.Producer
import experiments.data.validate.Validator
import experiments.data.preprocess.{CountWindowPreprocessor, FuncTestPreprocessor}

import scala.reflect.runtime.universe


object Main {
    def main(args: Array[String]): Unit = {
        if (args.length < 2) {
            printUsage()
        } else {
            args(0) match {
                case "-p" => produce(args.tail)
                case "-c" => convert(args.tail)
                case "-c2" => convert2(args.tail)
                case "-c3" => convert3(args.tail)
                case "-v" => validate(args.tail)
                case "-ft" => functest(args.tail)
                case "-w" | "-cw" => window(args.tail)
                case "-tw" => println("time window is not supported now.")
                case _ => printUsage()
            }
        }

    }

    def produce(args: Array[String]): Unit = {
        val experimentName = args.head
        val producerArgs = args.tail
        val producer = getObjectAs[Producer](s"experiments.data.produce.$experimentName.DataProducer")
        producer.produce(producerArgs)
    }

    def convert(args: Array[String]): Unit = {
        val systemName = args.head
        val convertArgs = args.tail
        val convertor = getObjectAs[Convertor](s"experiments.data.convert.$systemName.DataConvertor")
        convertor.convert(convertArgs)
    }

    def convert2(args: Array[String]): Unit = {
        val systemName = args.head
        val convertArgs = args.tail
        val convertor2 = getObjectAs[Convertor2](s"experiments.data.convert2.$systemName.DataConvertor2")
        convertor2.convert2(convertArgs)
    }

    def convert3(args: Array[String]): Unit = {
        val systemName = args.head
        val convertArgs = args.tail
        val convertor3 = getObjectAs[Convertor3](s"experiments.data.convert3.$systemName.DataConvertor3")
        convertor3.convert3(convertArgs)
    }

    def validate(args: Array[String]): Unit = {
        val systemName = args(0)
        val experimentName = args(1)
        val convertArgs = args.drop(2)
        val validator = getObjectAs[Validator](s"experiments.data.validate.$systemName.$experimentName.ResultValidator")
        validator.validate(convertArgs)
        println(s"validation of $systemName $experimentName passed.")
    }

    def window(args: Array[String]): Unit = {
        CountWindowPreprocessor.process(args)
    }

    def functest(args: Array[String]): Unit = {
        FuncTestPreprocessor.process(args)
    }

    def getObjectAs[T](name: String): T = {
        val runtimeMirror = universe.runtimeMirror(getClass.getClassLoader)
        val module = runtimeMirror.staticModule(name)
        val obj = runtimeMirror.reflectModule(module)
        obj.instance.asInstanceOf[T]
    }

    def printUsage(): Unit = {
        System.out.println(
            """Usage: data-tools -p experiment_name [args] for data-producer
              |   or: data-tools -c system_name [args] for data-convertor
              |   or: data-tools -v system_name experiment_name [args] for data-validator
              |   or: data-tools -w [args] for window-convertor
              |""".stripMargin)
        System.exit(1)
    }
}

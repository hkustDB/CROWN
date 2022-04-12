import RelationType.{Attributes, Payload, Relation}
import org.apache.flink.api.common.typeinfo.{BasicTypeInfo, TypeInformation}
import org.apache.flink.api.java.functions.KeySelector
import org.apache.flink.streaming.util.ProcessFunctionTestHarnesses
import org.scalatest.funsuite.AnyFunSuite

import java.io.ByteArrayOutputStream

class OutputResultTest extends AnyFunSuite{
    test("testOutputResultInRelation") {
        val INSERT = "Insert"
        val DELETE = "Delete"

        val processFunction = new L3ProcessFunctions(2)

        // wrap user defined function into a the corresponding operator
        val harness = ProcessFunctionTestHarnesses.forKeyedProcessFunction[Any, Payload, String](processFunction, new KeySelector[Payload, Any] {
            override def getKey(value: Payload): Any = value._3}, BasicTypeInfo.INT_TYPE_INFO.asInstanceOf[TypeInformation[Any]])

        val insert_ab_12 = Payload(INSERT, "G1", 0, Attributes(Array[Any](1, 2), Array[String]("A", "B")), 0)
        val insert_bc_23 = Payload(INSERT, "G2", 0, Attributes(Array[Any](2, 3), Array[String]("B", "C")), 0)
        val insert_cd_34 = Payload(INSERT, "G3", 0, Attributes(Array[Any](3, 4), Array[String]("C", "D")), 0)
        val insert_ab_02 = Payload(INSERT, "G1", 0, Attributes(Array[Any](0, 2), Array[String]("A", "B")), 0)
        val insert_cd_56 = Payload(INSERT, "G3", 0, Attributes(Array[Any](5, 6), Array[String]("C", "D")), 0)
        val insert_cd_57 = Payload(INSERT, "G3", 0, Attributes(Array[Any](5, 7), Array[String]("C", "D")), 0)
        val insert_bc_25 = Payload(INSERT, "G2", 0, Attributes(Array[Any](2, 5), Array[String]("B", "C")), 0)

        val delete_ab_02 = Payload(DELETE, "G1", 0, Attributes(Array[Any](0, 2), Array[String]("A", "B")), 0)
        val delete_bc_23 = Payload(DELETE, "G2", 0, Attributes(Array[Any](2, 3), Array[String]("B", "C")), 0)

        var outputStream: ByteArrayOutputStream = null

        outputStream = new ByteArrayOutputStream()
        Console.withOut(outputStream) {
            // state -> G1 = {(1, 2)}, G2 = {}, G3 = {}
            harness.processElement(insert_ab_12, 1)
            assert(outputStream.toString.equals(""))
        }

        outputStream = new ByteArrayOutputStream()
        Console.withOut(outputStream) {
            // state -> G1 = {(1, 2)}, G2 = {(2, 3)}, G3 = {}
            harness.processElement(insert_bc_23, 2)
            assert(outputStream.toString.equals(""))
        }

        outputStream = new ByteArrayOutputStream()
        Console.withOut(outputStream) {
            // state -> G1 = {(1, 2)}, G2 = {(2, 3)}, G3 = {(3, 4)}
            // should produce "+ (1,2,3,4) (A,B,C,D)" (potentially in different order)
            harness.processElement(insert_cd_34, 3)
            val output = reorder(outputStream.toString)
            assert(output.size == 1)
            assert(output.head._1)
            assert(output.head._2 == (1,2,3,4))
        }

        outputStream = new ByteArrayOutputStream()
        Console.withOut(outputStream) {
            // state -> G1 = {(1, 2), (0, 2)}, G2 = {(2, 3)}, G3 = {(3, 4)}
            // should produce "+ (0,2,3,4) (A,B,C,D)" (potentially in different order)
            harness.processElement(insert_ab_02, 4)
            val output = reorder(outputStream.toString)
            assert(output.size == 1)
            assert(output.head._1)
            assert(output.head._2 == (0,2,3,4))
        }

        outputStream = new ByteArrayOutputStream()
        Console.withOut(outputStream) {
            // state -> G1 = {(1, 2), (0, 2)}, G2 = {(2, 3)}, G3 = {(3, 4), (5, 6)}
            harness.processElement(insert_cd_56, 5)
            assert(outputStream.toString.equals(""))
        }

        outputStream = new ByteArrayOutputStream()
        Console.withOut(outputStream) {
            // state -> G1 = {(1, 2), (0, 2)}, G2 = {(2, 3)}, G3 = {(3, 4), (5, 6), (5, 7)}
            harness.processElement(insert_cd_57, 6)
            assert(outputStream.toString.equals(""))
        }

        outputStream = new ByteArrayOutputStream()
        Console.withOut(outputStream) {
            // state -> G1 = {(1, 2), (0, 2)}, G2 = {(2, 3), (2, 5)}, G3 = {(3, 4), (5, 6), (5, 7)}
            // should produce "+ (0,2,5,6) (A,B,C,D)" (potentially in different order)
            // should produce "+ (1,2,5,6) (A,B,C,D)" (potentially in different order)
            // should produce "+ (0,2,5,7) (A,B,C,D)" (potentially in different order)
            // should produce "+ (1,2,5,7) (A,B,C,D)" (potentially in different order)
            harness.processElement(insert_bc_25, 7)
            val output = reorder(outputStream.toString)
            assert(output.size == 4)
            assert(output.forall(o => o._1))
            val tuples = output.map(_._2)
            assert(tuples.contains((0,2,5,6)))
            assert(tuples.contains((0,2,5,7)))
            assert(tuples.contains((1,2,5,6)))
            assert(tuples.contains((1,2,5,7)))
        }

        outputStream = new ByteArrayOutputStream()
        Console.withOut(outputStream) {
            // state -> G1 = {(1, 2)}, G2 = {(2, 3), (2, 5)}, G3 = {(3, 4), (5, 6), (5, 7)}
            // should produce "- (0,2,5,6) (A,B,C,D)" (potentially in different order)
            // should produce "- (0,2,5,7) (A,B,C,D)" (potentially in different order)
            // should produce "- (0,2,3,4) (A,B,C,D)" (potentially in different order)
            harness.processElement(delete_ab_02, 8)
            val output = reorder(outputStream.toString)
            assert(output.size == 3)
            assert(output.forall(o => !o._1))
            val tuples = output.map(_._2)
            assert(tuples.contains((0,2,5,6)))
            assert(tuples.contains((0,2,5,7)))
            assert(tuples.contains((0,2,3,4)))
        }

        outputStream = new ByteArrayOutputStream()
        Console.withOut(outputStream) {
            // state -> G1 = {(1, 2)}, G2 = {(2, 5)}, G3 = {(3, 4), (5, 6), (5, 7)}
            // should produce "- (1,2,3,4) (A,B,C,D)" (potentially in different order)
            harness.processElement(delete_bc_23, 9)
            val output = reorder(outputStream.toString)
            assert(output.size == 1)
            assert(output.forall(o => !o._1))
            val tuples = output.map(_._2)
            assert(tuples.contains((1,2,3,4)))
        }
    }

    // "+ 2 , 3 , 1 , 4, B , C , A , D" -> (true, 1, 2, 3, 4)
    def reorder(s: String): List[(Boolean, (Int, Int, Int, Int))] = {
        println(s)
        val lines = s.split("\n")
        lines.map(line => {
            val b = (line.head == '+')
            val strings = line.substring(1).split(",").map(_.trim)
            assert(strings.length == 8)
            // Array("2","3","1","4") -> Array(2,3,1,4)
            val ints = strings.slice(0, 4).map(_.toInt)
            // Array("B","C","A","D") -> Array('B','C','A','D')
            val names = strings.slice(4, 8).map(_.charAt(0))
            val sorted = ints.zip(names).sortBy(t => t._2)
            (b, (sorted(0)._1, sorted(1)._1, sorted(2)._1, sorted(3)._1))
        }).toList
    }
}

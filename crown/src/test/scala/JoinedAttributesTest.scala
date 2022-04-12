import RelationType.{Attributes, JoinedAttributes}
import org.scalatest.funsuite.AnyFunSuite

class JoinedAttributesTest extends AnyFunSuite{
    test("constructor and equals") {
        val attr1 = Attributes(Array("a", "b"), Array("A", "B"))
        val joinedAttr1 = new JoinedAttributes(attr1)
        assert(joinedAttr1 equals attr1)

        val joinedAttr2 = new JoinedAttributes(attr1)
        assert(joinedAttr2 equals joinedAttr1)

        val joinedAttr3 = new JoinedAttributes(List(("A", "a"), ("B", "b")))
        assert(joinedAttr3 equals joinedAttr1)
    }

    test("apply") {
        val joinedAttr1 = new JoinedAttributes(List(("A", "a"), ("B", "b")))
        assert(joinedAttr1("A") == "a")
        assert(joinedAttr1("B") == "b")
        assertThrows[NullPointerException](joinedAttr1("C"))
    }

    test("join with Attributes") {
        val joinedAttr1 = new JoinedAttributes(List(("A", "a"), ("B", "b")))
        val attr1 = Attributes(Array("b", "c", "d"), Array("B", "C", "D"))
        val joinedAttr2 = joinedAttr1.join(attr1)
        assert(joinedAttr2("A") == "a")
        assert(joinedAttr2("B") == "b")
        assert(joinedAttr2("C") == "c")
        assert(joinedAttr2("D") == "d")

        val attr2 = Attributes(Array("b", "a"), Array("B", "A"))
        val joinedAttr3 = joinedAttr1.join(attr2)
        assert(joinedAttr3("A") == "a")
        assert(joinedAttr3("B") == "b")
        // check JoinedAttributes is immutable
        assertThrows[NullPointerException] {
            joinedAttr3("C")
        }
    }

    test("join with JoinedAttributes") {
        val joinedAttr1 = new JoinedAttributes(List(("A", "a"), ("B", "b")))
        val joinedAttr2 = new JoinedAttributes(List(("B", "b"), ("C", "c"), ("D", "d")))

        val joinedAttr3 = joinedAttr1.join(joinedAttr2)
        assert(joinedAttr3("A") == "a")
        assert(joinedAttr3("B") == "b")
        assert(joinedAttr3("C") == "c")
        assert(joinedAttr3("D") == "d")

        val joinedAttr4 = new JoinedAttributes(List(("B", "b"), ("A", "a")))
        val joinedAttr5 = joinedAttr1.join(joinedAttr4)
        assert(joinedAttr5("A") == "a")
        assert(joinedAttr5("B") == "b")
        // check JoinedAttributes is immutable
        assertThrows[NullPointerException] {
            joinedAttr5("C")
        }
    }

    test("projection") {
        val joinedAttr1 = new JoinedAttributes(List(("A", "a"), ("B", "b"), ("C", "c"), ("D", "d")))
        val joinedAttr2 = joinedAttr1.projection(Array("A", "C"))
        assert(joinedAttr2 equals new JoinedAttributes(List(("A", "a"), ("C", "c"))))
        val joinedAttr3 = joinedAttr1.projection(Array("B", "D"))
        assert(joinedAttr3 equals new JoinedAttributes(List(("B", "b"), ("D", "d"))))

        // project to single key
        val joinedAttr4 = joinedAttr1.projection(Array("C"))
        assert(joinedAttr4 equals new JoinedAttributes(List(("C", "c"))))

        // project to non-exist key
        val joinedAttr5 = joinedAttr1.projection(Array("E"))
        assert(joinedAttr5 equals new JoinedAttributes(List()))

        // project to keys that contains non-exist key
        val joinedAttr6 = joinedAttr1.projection(Array("D", "E"))
        assert(joinedAttr6 equals new JoinedAttributes(List(("D", "d"))))
    }

    test("equals") {
        val joinedAttr1 = new JoinedAttributes(List(("A", "a"), ("B", "b")))
        val joinedAttr2 = new JoinedAttributes(List(("B", "b"), ("C", "c"), ("D", "d")))
        val joinedAttr3 = new JoinedAttributes(List(("B", "b"), ("A", "a")))
        val joinedAttr4 = new JoinedAttributes(List(("A", "a"), ("B", "b"), ("C", "c")))

        assert(!joinedAttr1.equals(joinedAttr2))
        assert(!joinedAttr2.equals(joinedAttr1))

        // order insensitive
        assert(joinedAttr1 equals joinedAttr3)
        assert(joinedAttr3 equals joinedAttr1)

        // subset also returns false
        assert(!joinedAttr1.equals(joinedAttr4))
        assert(!joinedAttr4.equals(joinedAttr1))

        assert(!joinedAttr1.equals("any object"))
    }

    test("hashcode") {
        val joinedAttr1 = new JoinedAttributes(List(("A", "a"), ("B", "b")))
        val joinedAttr2 = new JoinedAttributes(List(("B", "b"), ("C", "c"), ("D", "d")))
        val joinedAttr3 = new JoinedAttributes(List(("B", "b"), ("A", "a")))

        assert(joinedAttr1.hashCode() != joinedAttr2.hashCode())
        // order insensitive
        assert(joinedAttr1.hashCode() == joinedAttr3.hashCode())
    }

    test("containsKey") {
        val joinedAttr1 = new JoinedAttributes(List(("A", "a"), ("B", "b")))

        assert(joinedAttr1 containsKey "A")
        assert(joinedAttr1 containsKey "B")
        assert(!joinedAttr1.containsKey("C"))
    }

    test("rename") {
        val joinedAttr1 = new JoinedAttributes(List(("A", "a"), ("B", "b")))
        joinedAttr1.rename("A", "A'")

        assert(joinedAttr1("A'") == "a")
        assert(!joinedAttr1.containsKey("A"))
    }

    test("toString") {
        val list = List(("B", "b"), ("C", "c"), ("D", "d"))
        val joinedAttr1 = new JoinedAttributes(list)
        assert(joinedAttr1.toString == list.mkString(" , "))
    }
}

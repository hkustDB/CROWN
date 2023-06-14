package RelationType

/**
 * Currently, the bag relation can only be leaf node, with no child, and the node cannot be
 * output node.  If some or all attributes need to be output, the user should put all output
 * attributes in the [JOIN_KEY] and create a generalized relation over the bag relation.
 */
abstract class Bag(name : String, joinkey : Array[String], nextRelation : Relation, override val deltaEnumMode: Int)
  extends Relation(name, joinkey, nextRelation, deltaEnumMode, 0, false) {

}

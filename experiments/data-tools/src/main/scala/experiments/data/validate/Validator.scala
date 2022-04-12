package experiments.data.validate

trait Validator {
    def validate(args: Array[String]): Unit
}

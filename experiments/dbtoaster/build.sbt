name := "experiments-dbtoaster"
version := "0.1"
scalaVersion := "2.11.12"

libraryDependencies ++= Seq(
    "org.apache.spark" %% "spark-core" % "2.2.3",
    "org.apache.hadoop" % "hadoop-client" % "2.6.5",
    "com.typesafe.akka" %% "akka-actor" % "2.5.32",
    "org.scala-lang" % "scala-reflect" % scalaVersion.value,
    "com.github.sbt" % "junit-interface" % "0.13.2" % Test
)

mainClass in Compile := Some("experiments.dbtoaster.Main")
assemblyOutputPath in assembly := file("target/experiments-dbtoaster.jar")
assemblyMergeStrategy in assembly := {
    case PathList("META-INF", "services", xs @ _*) => MergeStrategy.filterDistinctLines
    case PathList("META-INF", xs @ _*) => MergeStrategy.discard
    case x => MergeStrategy.first
}
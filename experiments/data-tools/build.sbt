name := "data-tools"
version := "0.1"
scalaVersion := "2.13.1"

mainClass in Compile := Some("experiments.data.Main")

assemblyOutputPath in assembly := file("target/data-tools.jar")

libraryDependencies ++= Seq(
    "com.opencsv" % "opencsv" % "5.5.2",
    "org.scala-lang" % "scala-reflect" % scalaVersion.value,
    "org.scala-lang.modules" %% "scala-xml" % "2.0.0",
    "com.github.sbt" % "junit-interface" % "0.13.2" % Test
)

package experiments.dbtoaster

import ddbt.lib.Helper.ExperimentHelperListener

trait Executable {
    def exec(args: Array[String], listener: ExperimentHelperListener)
}

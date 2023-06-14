spec.query.name=joinproject
spec.tasks.count=18

# 3-Hop
task1.system.name=crown
task1.experiment.name=length3_project
task1.minicluster.entry.class=L3ProjDistributedJob
task1.test.entry.class=fake
task2.system.name=flink
task2.experiment.name=length3_project
task3.system.name=dbtoaster_cpp
task3.experiment.name=length3_project
task4.system.name=dbtoaster
task4.experiment.name=length3_project
task4.input.insert.only=false
task4.line.count.multiplier=3
task4.dataset.name=length3_project_perf_del
task5.system.name=crown_delta
task5.experiment.name=length3_project
task5.minicluster.entry.class=L3ProjDistributedJob
task5.test.entry.class=fake
task6.system.name=trill
task6.experiment.name=length3_project
task6.graph.inputsize=508837

# 4-Hop
task7.system.name=crown
task7.experiment.name=length4_project
task7.minicluster.entry.class=L4ProjDistributedJob
task7.test.entry.class=L4ProjGraphTest
task8.system.name=flink
task8.experiment.name=length4_project
task9.system.name=dbtoaster_cpp
task9.experiment.name=length4_project
task10.system.name=dbtoaster
task10.experiment.name=length4_project
task10.input.insert.only=false
task10.line.count.multiplier=4
task10.dataset.name=length4_project_perf_del
task11.system.name=crown_delta
task11.experiment.name=length4_project
task11.minicluster.entry.class=L4ProjDistributedJob
task11.test.entry.class=L4ProjGraphTest
task12.system.name=trill
task12.experiment.name=length4_project
task12.graph.inputsize=508837

# dumbbell
task13.system.name=crown
task13.experiment.name=dumbbell
task13.minicluster.entry.class=DumbbellCrownTriangleProjectJob
task13.test.entry.class=fake
task13.filter.condition.value=0
task14.system.name=flink
task14.experiment.name=dumbbell
task15.system.name=dbtoaster_cpp
task15.experiment.name=dumbbell
task16.system.name=dbtoaster
task16.experiment.name=dumbbell
task16.input.insert.only=false
task16.line.count.multiplier=7
task16.dataset.name=dumbbell_perf_del
task17.system.name=crown_delta
task17.experiment.name=dumbbell
task17.minicluster.entry.class=DumbbellCrownTriangleProjectJob
task17.test.entry.class=fake
task17.filter.condition.value=0
task18.system.name=trill
task18.experiment.name=dumbbell
task18.graph.inputsize=508837
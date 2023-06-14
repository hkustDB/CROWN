spec.query.name=aggquery
spec.tasks.count=12

# star_cnt
task1.system.name=crown
task1.experiment.name=star_cnt
task1.minicluster.entry.class=StarCntDistributedJob
task1.test.entry.class=fake
task2.system.name=flink
task2.experiment.name=star_cnt
task3.system.name=dbtoaster_cpp
task3.experiment.name=star_cnt
task4.system.name=dbtoaster
task4.experiment.name=star_cnt
task4.input.insert.only=false
task4.line.count.multiplier=4
task4.dataset.name=star_cnt_perf_del
task5.system.name=crown_delta
task5.experiment.name=star_cnt
task5.minicluster.entry.class=StarCntDistributedJob
task5.test.entry.class=fake
task6.system.name=trill
task6.experiment.name=star_cnt
task6.graph.inputsize=508837

# snb4_window
task7.system.name=crown
task7.experiment.name=snb4_window
task7.minicluster.entry.class=SNBQ4Job
task7.test.entry.class=fake
task8.system.name=flink
task8.experiment.name=snb4_window
task9.system.name=dbtoaster_cpp
task9.experiment.name=snb4_window
task10.system.name=dbtoaster
task10.experiment.name=snb4_window
task10.input.insert.only=false
task10.dataset.name=snb4_window_perf_del
task11.system.name=crown_delta
task11.experiment.name=snb4_window
task11.minicluster.entry.class=SNBQ4Job
task11.test.entry.class=fake
task12.system.name=trill
task12.experiment.name=snb4_window
task12.graph.inputsize=0
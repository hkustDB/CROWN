spec.query.name=parallelism
spec.tasks.count=24

# CROWN 4-Hop
task1.system.name=crown
task1.experiment.name=length4_filter
task1.minicluster.entry.class=L4DistributedJob
task1.test.entry.class=L4GraphTest
task1.filter.condition.value=32684
task1.executor.cores=0
task1.minicluster.parallelism=1
task2.system.name=crown
task2.experiment.name=length4_filter
task2.minicluster.entry.class=L4DistributedJob
task2.test.entry.class=L4GraphTest
task2.filter.condition.value=32684
task2.executor.cores=0-1
task2.minicluster.parallelism=2
task3.system.name=crown
task3.experiment.name=length4_filter
task3.minicluster.entry.class=L4DistributedJob
task3.test.entry.class=L4GraphTest
task3.filter.condition.value=32684
task3.executor.cores=0-3
task3.minicluster.parallelism=4
task4.system.name=crown
task4.experiment.name=length4_filter
task4.minicluster.entry.class=L4DistributedJob
task4.test.entry.class=L4GraphTest
task4.filter.condition.value=32684
task4.executor.cores=0-7
task4.minicluster.parallelism=8
task5.system.name=crown
task5.experiment.name=length4_filter
task5.minicluster.entry.class=L4DistributedJob
task5.test.entry.class=L4GraphTest
task5.filter.condition.value=32684
task5.executor.cores=0-15
task5.minicluster.parallelism=16
task6.system.name=crown
task6.experiment.name=length4_filter
task6.minicluster.entry.class=L4DistributedJob
task6.test.entry.class=L4GraphTest
task6.filter.condition.value=32684
task6.executor.cores=0-31
task6.minicluster.parallelism=32

# Flink 4-Hop
task7.system.name=flink
task7.experiment.name=length4_filter
task7.filter.condition.value=32684
task7.executor.cores=0
task7.perf.parallelism=1
task8.system.name=flink
task8.experiment.name=length4_filter
task8.filter.condition.value=32684
task8.executor.cores=0-1
task8.perf.parallelism=2
task9.system.name=flink
task9.experiment.name=length4_filter
task9.filter.condition.value=32684
task9.executor.cores=0-3
task9.perf.parallelism=4
task10.system.name=flink
task10.experiment.name=length4_filter
task10.filter.condition.value=32684
task10.executor.cores=0-7
task10.perf.parallelism=8
task11.system.name=flink
task11.experiment.name=length4_filter
task11.filter.condition.value=32684
task11.executor.cores=0-15
task11.perf.parallelism=16
task12.system.name=flink
task12.experiment.name=length4_filter
task12.filter.condition.value=32684
task12.executor.cores=0-31
task12.perf.parallelism=32

# CROWN SNBQ3
task13.system.name=crown
task13.experiment.name=snb3_window
task13.minicluster.entry.class=SNBQ3Job
task13.test.entry.class=fake
task13.filter.condition.value=100000
task13.executor.cores=0
task13.minicluster.parallelism=1
task14.system.name=crown
task14.experiment.name=snb3_window
task14.minicluster.entry.class=SNBQ3Job
task14.test.entry.class=fake
task14.filter.condition.value=100000
task14.executor.cores=0-1
task14.minicluster.parallelism=2
task15.system.name=crown
task15.experiment.name=snb3_window
task15.minicluster.entry.class=SNBQ3Job
task15.test.entry.class=fake
task15.filter.condition.value=100000
task15.executor.cores=0-3
task15.minicluster.parallelism=4
task16.system.name=crown
task16.experiment.name=snb3_window
task16.minicluster.entry.class=SNBQ3Job
task16.test.entry.class=fake
task16.filter.condition.value=100000
task16.executor.cores=0-7
task16.minicluster.parallelism=8
task17.system.name=crown
task17.experiment.name=snb3_window
task17.minicluster.entry.class=SNBQ3Job
task17.test.entry.class=fake
task17.filter.condition.value=100000
task17.executor.cores=0-15
task17.minicluster.parallelism=16
task18.system.name=crown
task18.experiment.name=snb3_window
task18.minicluster.entry.class=SNBQ3Job
task18.test.entry.class=fake
task18.filter.condition.value=100000
task18.executor.cores=0-31
task18.minicluster.parallelism=32

# Dbtoaster SNBQ3
task19.system.name=dbtoaster
task19.experiment.name=snb3_window
task19.input.insert.only=false
task19.dataset.name=snb3_window_perf_del
task19.executor.cores=0
task19.executor.memory=100G
task19.master.url=local[1]
task19.partitions.num=1
task20.system.name=dbtoaster
task20.experiment.name=snb3_window
task20.input.insert.only=false
task20.dataset.name=snb3_window_perf_del
task20.executor.cores=0-1
task20.executor.memory=50G
task20.master.url=local[2]
task20.partitions.num=2
task21.system.name=dbtoaster
task21.experiment.name=snb3_window
task21.input.insert.only=false
task21.dataset.name=snb3_window_perf_del
task21.executor.cores=0-3
task21.executor.memory=25G
task21.master.url=local[4]
task21.partitions.num=4
task22.system.name=dbtoaster
task22.experiment.name=snb3_window
task22.input.insert.only=false
task22.dataset.name=snb3_window_perf_del
task22.executor.cores=0-7
task22.executor.memory=12G
task22.master.url=local[8]
task22.partitions.num=8
task23.system.name=dbtoaster
task23.experiment.name=snb3_window
task23.input.insert.only=false
task23.dataset.name=snb3_window_perf_del
task23.executor.cores=0-15
task23.executor.memory=6G
task23.master.url=local[16]
task23.partitions.num=16
task24.system.name=dbtoaster
task24.experiment.name=snb3_window
task24.input.insert.only=false
task24.dataset.name=snb3_window_perf_del
task24.executor.cores=0-31
task24.executor.memory=3G
task24.master.url=local[32]
task24.partitions.num=32
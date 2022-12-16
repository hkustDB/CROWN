## How to run 2comb experiments
1. Add 'TwoComb' to valid_experiment_names in common.sh
2. Remove 'dbtoaster' from valid_system_names because dbtoaster(spark) raises compilation error in TwoComb
3. Use `TwoComb/convert_graph.sh` to convert a graph into input files
4. Create `flink/src/main/resources/TwoComb/perf.cfg`, compute window size and window step by the rows count. Also add the `path.to.graph/v1/v2.csv` to perf.cfg.
5. Modify the file paths in `dbtoaster_cpp/TwoComb/query.sql.template`
6. Build
7. Check `crown/TwoComb/perf.cfg`. Replaced the file with `path.to.data.csv` as the converted graph file.
8. Edit `trill/bin/Debug/net5.0/experiments-trill.dll.config`, change `TwoComb.perf.path` to the path of converted graph file.
9. Execute
package experiments.flink.length3_filter;

import experiments.flink.Executable;
import experiments.flink.utils.ResourcesUtil;
import org.apache.flink.api.java.tuple.Tuple2;
import org.apache.flink.api.java.tuple.Tuple6;
import org.apache.flink.configuration.Configuration;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.functions.sink.DiscardingSink;
import org.apache.flink.table.api.Table;
import org.apache.flink.table.api.bridge.java.StreamTableEnvironment;
import org.apache.flink.types.Row;

import java.util.LinkedList;
import java.util.List;
import java.util.Properties;

public class Query implements Executable {
    private Properties properties;

    public Query(Properties properties) {
        this.properties = properties;
    }

    public List<Tuple6<Boolean, Integer, Integer, Integer, Integer, String>> exec() throws Exception {
        int parallelism = Integer.parseInt(properties.getProperty("flink.job.parallelism"));

        Configuration configuration = new Configuration();
        // networkMemory default value = "64Mb"
        int networkMemory = Math.max(64, 40 * parallelism);
        configuration.setString("taskmanager.memory.network.min", networkMemory + "Mb");
        configuration.setString("taskmanager.memory.network.max", networkMemory + "Mb");

        // set heartbeat.timeout to 300sec
        configuration.setLong("heartbeat.timeout", 300 * 1000);
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment(configuration);

        env.setParallelism(parallelism);
        env.getConfig().enableObjectReuse();
        StreamTableEnvironment tableEnv = StreamTableEnvironment.create(env);

        ResourcesUtil resourcesUtil = new ResourcesUtil(properties);

        String createTableGraph = resourcesUtil.readResourceFile("length3_filter/graph.sql");
        tableEnv.executeSql(createTableGraph);

        String createViewGraphWindowed = resourcesUtil.readResourceFile("length3_filter/window.sql");
        tableEnv.executeSql(createViewGraphWindowed);

        String query = resourcesUtil.readResourceFile("length3_filter/query.sql");
        Table table = tableEnv.sqlQuery(query);
        DataStream<Tuple2<Boolean, Row>> result = tableEnv.toRetractStream(table, Row.class);

        if (properties.getProperty("discard.tuples.in.sink", "true").equals("true")) {
            // use DiscardingSink to avoid writing tuples to output in perf test
            result.addSink(new DiscardingSink<>());
            env.execute();
            return null;
        } else {
            // collect and return the result for func test
            List<Tuple6<Boolean, Integer, Integer, Integer, Integer, String>> list = new LinkedList<>();
            result.executeAndCollect().forEachRemaining(row ->
                    list.add(new Tuple6<>(
                            row.f0,
                            (Integer) row.f1.getField(0),
                            (Integer) row.f1.getField(1),
                            (Integer) row.f1.getField(2),
                            (Integer) row.f1.getField(3),
                            row.f1.getField(4).toString()
                    ))
            );
            return list;
        }
    }
}

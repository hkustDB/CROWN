package experiments.flink.snb3_arbitrary;

import experiments.flink.Executable;
import experiments.flink.utils.ResourcesUtil;
import org.apache.flink.api.java.tuple.Tuple2;
import org.apache.flink.api.java.tuple.Tuple7;
import org.apache.flink.configuration.Configuration;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.functions.sink.DiscardingSink;
import org.apache.flink.streaming.api.functions.sink.SinkFunction;
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

    public List<Tuple7<Boolean, Integer, Integer, Integer, Integer, Integer, String>> exec() throws Exception {
        int parallelism = Integer.parseInt(properties.getProperty("flink.job.parallelism"));

        Configuration configuration = new Configuration();
        // networkMemory default value = "64Mb"
        int networkMemory = Math.max(64, 40 * parallelism);
        configuration.setString("taskmanager.memory.network.min", networkMemory + "Mb");
        configuration.setString("taskmanager.memory.network.max", networkMemory + "Mb");

        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment(configuration);

        env.setParallelism(parallelism);
        env.getConfig().enableObjectReuse();
        StreamTableEnvironment tableEnv = StreamTableEnvironment.create(env);

        ResourcesUtil resourcesUtil = new ResourcesUtil(properties);

        String createTableMessage = resourcesUtil.readResourceFile("snb3_arbitrary/message.sql");
        tableEnv.executeSql(createTableMessage);

        String createTablePerson = resourcesUtil.readResourceFile("snb3_arbitrary/person.sql");
        tableEnv.executeSql(createTablePerson);

        String createTableKnows = resourcesUtil.readResourceFile("snb3_arbitrary/knows.sql");
        tableEnv.executeSql(createTableKnows);

        String query = resourcesUtil.readResourceFile("snb3_arbitrary/query.sql");
        Table table = tableEnv.sqlQuery(query);
        DataStream<Tuple2<Boolean, Row>> result = tableEnv.toRetractStream(table, Row.class);

        if (properties.getProperty("discard.tuples.in.sink", "true").equals("true")) {
            // use DiscardingSink to avoid writing tuples to output in perf test
            result.addSink(new DiscardingSink<>());
            env.execute();
            return null;
        } else {
            // collect and return the result for func test
            List<Tuple7<Boolean, Integer, Integer, Integer, Integer, Integer, String>> list = new LinkedList<>();
            result.executeAndCollect().forEachRemaining(row ->
                    list.add(new Tuple7<>(
                            row.f0,
                            (Integer) row.f1.getField(0),
                            (Integer) row.f1.getField(1),
                            (Integer) row.f1.getField(2),
                            (Integer) row.f1.getField(3),
                            (Integer) row.f1.getField(4),
                            row.f1.getField(5).toString()
                    ))
            );
            return list;
        }
    }
}

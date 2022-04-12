package experiments.flink.star_cnt;

import org.apache.flink.api.java.tuple.Tuple2;
import org.apache.flink.api.java.tuple.Tuple4;
import org.apache.flink.api.java.tuple.Tuple5;
import org.apache.flink.api.java.tuple.Tuple7;
import org.junit.Assert;
import org.junit.Test;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.*;
import java.util.stream.Collectors;

public class FuncTest {
    @Test
    public void testFunc() throws Exception {
        Properties p = new Properties();
        p.load(FuncTest.class.getClassLoader().getResourceAsStream("star_cnt/func.cfg"));

        // disable discarding sink in exec
        p.setProperty("discard.tuples.in.sink", "false");

        // flink approach
        Map<String, Map<Integer, Long>> flinkResult = flinkApproach(p);
        List<String> flinkGroups = flinkResult.keySet().stream().sorted().collect(Collectors.toList());

        // trivial approach
        Map<Integer, Map<Integer, Long>> trivialResult = trivialApproach(p);
        List<Integer> trivialGroups = trivialResult.keySet().stream().sorted().collect(Collectors.toList());

        Assert.assertEquals(trivialGroups.size(), flinkGroups.size());
        for (int i = 0; i < flinkGroups.size(); i++) {
            Map<Integer, Long> flinkGroupResult = flinkResult.get(flinkGroups.get(i));
            Map<Integer, Long> trivialGroupResult = trivialResult.get(trivialGroups.get(i));
            Assert.assertEquals(flinkGroupResult.size(), trivialGroupResult.size());
            flinkGroupResult.forEach((key, value) -> Assert.assertEquals(trivialGroupResult.get(key), value));
        }
    }

    /**
     * flink approach of Star experiment
     * @return a Map, key = group(window_start), value = star paths in that window
     */
    public Map<String, Map<Integer, Long>> flinkApproach(Properties p) throws Exception {
        Query query = new Query(p);
        Map<String, Map<Integer, Long>> result = new HashMap<>();
        List<Tuple4<Boolean, Integer, Long, String>> output = query.exec();
        output.forEach(row -> {
            String key = row.f3;
            result.putIfAbsent(key, new HashMap<>());
            result.get(key).put(row.f1, row.f2);
        });
        return result;
    }

    public Map<Integer, Map<Integer, Long>> trivialApproach(Properties p) throws IOException {
        String path = p.getProperty("path.to.data.raw");
        int windowSize = Integer.parseInt(p.getProperty("hop.window.size"));
        int windowStep = Integer.parseInt(p.getProperty("hop.window.step"));
        Assert.assertEquals(windowSize, windowStep * 2);

        List<String> lines = new LinkedList<>();
        BufferedReader reader = new BufferedReader(new InputStreamReader(new FileInputStream(path)));
        String line = reader.readLine();
        while (line != null) {
            lines.add(line);
            line = reader.readLine();
        }

        // key = group, value = edges in that group
        // key in edges = src, values in edges = dsts
        Map<Integer, Map<Integer, List<Integer>>> buckets = new HashMap<>();
        // bypass the capture by value
        int[] cnt = new int[] {0};
        lines.forEach(l -> {
            String[] strings = l.split(",");
            // since the windowSize must be 2 times of windowStep, every event must lies in one even index group
            // for example, step = 10, size = 20, we have groups [0, 20), [10, 30), [20, 40), [30, 50), ...
            // then event with time 37 lies in group [20, 40) with index 2
            int index1 = (cnt[0] / windowSize) * 2;
            buckets.putIfAbsent(index1, new HashMap<>());
            buckets.get(index1).putIfAbsent(Integer.parseInt(strings[0]), new LinkedList<>());
            buckets.get(index1).get(Integer.parseInt(strings[0])).add(Integer.parseInt(strings[1]));

            // then we determine this event lies in the left or right half of the group
            int index2 = -1;
            if (cnt[0] % windowSize >= windowStep) {
                // lies in the right part, so this event also belongs to group index1 + 1
                index2 = index1 + 1;
            } else {
                index2 = index1 - 1;
            }
            buckets.putIfAbsent(index2, new HashMap<>());
            buckets.get(index2).putIfAbsent(Integer.parseInt(strings[0]), new LinkedList<>());
            buckets.get(index2).get(Integer.parseInt(strings[0])).add(Integer.parseInt(strings[1]));
            cnt[0] += 1;
        });

        Set<Integer> trivialGroups = buckets.keySet();
        // joined result of each group
        Map<Integer, Map<Integer, Long>> trivialResult = new HashMap<>();
        trivialGroups.forEach(group -> {
            Map<Integer, List<Integer>> edges = buckets.get(group);
            Map<Integer, Long> result = new HashMap<>();
            edges.keySet().forEach(src -> {
                List<Integer> targets = edges.get(src);
                long size = targets.size();
                result.put(src, size * size * size * size);
            });

            if (result.size() > 0)
                trivialResult.put(group, result);
        });

        return trivialResult;
    }
}

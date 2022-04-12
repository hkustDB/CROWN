package experiments.flink;

import java.lang.reflect.Constructor;
import java.util.Properties;

public class Main {
    public static void main(String[] args) throws Exception {
        String experiment = args[0];

        Properties p = new Properties();
        p.load(Main.class.getClassLoader().getResourceAsStream(experiment + "/perf.cfg"));

        Constructor constructor = Class.forName("experiments.flink." + experiment + ".Query").getConstructor(Properties.class);
        Executable query = (Executable) constructor.newInstance(p);
        query.exec();
        System.out.println("experiment: " + experiment + " finished.");
    }
}

package experiments.flink.utils;

import org.junit.Assert;
import org.junit.Test;

import java.util.Properties;

public class ResourcesUtilTest {
    @Test
    public void test() throws Exception {
        Properties p = new Properties();
        p.load(ResourcesUtilTest.class.getClassLoader().getResourceAsStream("utils/unittest.properties"));
        ResourcesUtil resourcesUtil = new ResourcesUtil(p);
        String s = resourcesUtil.readResourceFile("utils/unittest.txt");
        Assert.assertEquals("replace the following blank some value and check.", s);
    }
}

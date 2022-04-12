package experiments.flink.utils;

import org.apache.commons.io.IOUtils;

import java.io.InputStream;
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Enumeration;
import java.util.Properties;
import java.util.Set;

public class ResourcesUtil {
    Properties properties;

    public ResourcesUtil(Properties properties) {
        this.properties = properties;
    }

    public String readResourceFile(String file) throws Exception {
        InputStream inputStream = ResourcesUtil.class.getClassLoader().getResourceAsStream(file);
        String string = IOUtils.toString(inputStream, Charset.defaultCharset());
        return render(string);
    }

    private String render(String string) {
        if (string == null || string.equals(""))
            return string;
        else {
            String result = string;
            Set<String> names = properties.stringPropertyNames();
            for (String name : names) {
                result = result.replaceAll("\\$\\{" + name + "}", properties.getProperty(name));
            }

            return result;
        }
    }
}

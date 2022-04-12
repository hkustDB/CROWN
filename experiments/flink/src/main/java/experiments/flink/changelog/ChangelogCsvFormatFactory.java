package experiments.flink.changelog;

import org.apache.flink.api.common.serialization.DeserializationSchema;
import org.apache.flink.api.common.serialization.SerializationSchema;
import org.apache.flink.configuration.ConfigOption;
import org.apache.flink.configuration.ConfigOptions;
import org.apache.flink.configuration.ReadableConfig;
import org.apache.flink.table.connector.format.DecodingFormat;
import org.apache.flink.table.connector.format.EncodingFormat;
import org.apache.flink.table.data.RowData;
import org.apache.flink.table.factories.DeserializationFormatFactory;
import org.apache.flink.table.factories.DynamicTableFactory;
import org.apache.flink.table.factories.FactoryUtil;
import org.apache.flink.table.factories.SerializationFormatFactory;

import java.util.Collections;
import java.util.HashSet;
import java.util.Set;

public class ChangelogCsvFormatFactory implements SerializationFormatFactory, DeserializationFormatFactory {
    public final static String IDENTIFIER = "csv-changelog";

    public static final ConfigOption<String> COLUMN_DELIMITER = ConfigOptions.key("column-delimiter")
            .stringType()
            .defaultValue("|");

    public static final ConfigOption<String> INSERT_TAG = ConfigOptions.key("insert-tag")
            .stringType()
            .defaultValue("+");

    public static final ConfigOption<String> DELETE_TAG = ConfigOptions.key("delete-tag")
            .stringType()
            .defaultValue("-");

    @Override
    public EncodingFormat<SerializationSchema<RowData>> createEncodingFormat(DynamicTableFactory.Context context, ReadableConfig formatOptions) {
        FactoryUtil.validateFactoryOptions(this, formatOptions);
        final String delimiter = formatOptions.get(COLUMN_DELIMITER);
        final String insertTag = formatOptions.get(INSERT_TAG);
        final String deleteTag = formatOptions.get(DELETE_TAG);

        return new ChangelogCsvFormat(delimiter, insertTag, deleteTag);
    }

    @Override
    public DecodingFormat<DeserializationSchema<RowData>> createDecodingFormat(DynamicTableFactory.Context context, ReadableConfig formatOptions) {
        FactoryUtil.validateFactoryOptions(this, formatOptions);
        final String delimiter = formatOptions.get(COLUMN_DELIMITER);
        final String insertTag = formatOptions.get(INSERT_TAG);
        final String deleteTag = formatOptions.get(DELETE_TAG);

        return new ChangelogCsvFormat(delimiter, insertTag, deleteTag);
    }

    @Override
    public String factoryIdentifier() {
        return IDENTIFIER;
    }

    @Override
    public Set<ConfigOption<?>> requiredOptions() {
        return Collections.emptySet();
    }

    @Override
    public Set<ConfigOption<?>> optionalOptions() {
        Set<ConfigOption<?>> options = new HashSet<>();
        options.add(COLUMN_DELIMITER);
        options.add(INSERT_TAG);
        options.add(DELETE_TAG);
        return options;
    }
}

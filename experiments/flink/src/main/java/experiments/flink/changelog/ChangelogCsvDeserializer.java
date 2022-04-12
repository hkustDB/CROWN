package experiments.flink.changelog;

import org.apache.flink.api.common.serialization.DeserializationSchema;
import org.apache.flink.api.common.typeinfo.TypeInformation;
import org.apache.flink.table.connector.RuntimeConverter;
import org.apache.flink.table.connector.source.DynamicTableSource;
import org.apache.flink.table.data.RowData;
import org.apache.flink.table.types.logical.LogicalType;
import org.apache.flink.table.types.logical.LogicalTypeRoot;
import org.apache.flink.types.Row;
import org.apache.flink.types.RowKind;

import java.sql.Date;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.time.LocalDate;
import java.util.List;
import java.util.regex.Pattern;

public class ChangelogCsvDeserializer implements DeserializationSchema<RowData> {
    private final List<LogicalType> parsingTypes;
    private final DynamicTableSource.DataStructureConverter converter;
    private final TypeInformation<RowData> producedTypeInfo;
    private final String delimiter;
    private final String insertTag;
    private final String deleteTag;

    public ChangelogCsvDeserializer(List<LogicalType> parsingTypes,
                                    DynamicTableSource.DataStructureConverter converter,
                                    TypeInformation<RowData> producedTypeInfo,
                                    String delimiter,
                                    String insertTag,
                                    String deleteTag) {
        this.parsingTypes = parsingTypes;
        this.converter = converter;
        this.producedTypeInfo = producedTypeInfo;
        this.delimiter = delimiter;
        this.insertTag = insertTag;
        this.deleteTag = deleteTag;
    }

    private static Object parse(LogicalTypeRoot root, String value) {
        switch (root) {
            case INTEGER:
                return Integer.parseInt(value);
            case VARCHAR:
                if (!value.equals("\\N"))
                    return value;
                else
                    return null;
            case BIGINT:
                if (!value.equals("\\N"))
                    return Long.parseLong(value);
                else
                    return null;
            case BOOLEAN:
                return value.equalsIgnoreCase("true");
            case DATE:
                return LocalDate.parse(value);
            default:
                throw new IllegalArgumentException();
        }
    }

    private RowKind parseRowKind(String tag) {
        if (tag.equals(insertTag))
            return RowKind.INSERT;
        else if (tag.equals(deleteTag))
            return RowKind.DELETE;
        else
            throw new IllegalArgumentException("unrecognizable RowKind tag: " + tag + ", use '" + insertTag + "' or '" + deleteTag + "' instead.");
    }

    @Override
    public RowData deserialize(byte[] bytes) {
        final String[] columns = new String(bytes).split(Pattern.quote(delimiter), -1);

        final RowKind kind = parseRowKind(columns[0]);
        final Row row = new Row(kind, parsingTypes.size());
        for (int i = 0; i < parsingTypes.size(); i++) {
            try {
                Object obj = parse(parsingTypes.get(i).getTypeRoot(), columns[i + 1]);
            } catch (Exception e) {
                System.out.println(i);
            }
            row.setField(i, parse(parsingTypes.get(i).getTypeRoot(), columns[i + 1]));
        }

        return (RowData) converter.toInternal(row);
    }

    @Override
    public boolean isEndOfStream(RowData rowData) {
        return false;
    }

    @Override
    public TypeInformation<RowData> getProducedType() {
        return this.producedTypeInfo;
    }

    @Override
    public void open(InitializationContext context) {
        this.converter.open(RuntimeConverter.Context.create(ChangelogCsvDeserializer.class.getClassLoader()));
    }
}

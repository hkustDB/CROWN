package experiments.flink.changelog;

import org.apache.flink.api.common.serialization.SerializationSchema;
import org.apache.flink.table.data.RowData;
import org.apache.flink.table.types.logical.LogicalType;
import org.apache.flink.table.types.logical.LogicalTypeRoot;
import org.apache.flink.types.RowKind;

import java.nio.charset.StandardCharsets;
import java.util.List;

public class ChangelogCsvSerializer implements SerializationSchema<RowData> {
    private final List<LogicalType> parsingTypes;
    private final String delimiter;
    private final String insertTag;
    private final String deleteTag;

    public ChangelogCsvSerializer(List<LogicalType> parsingTypes, String delimiter, String insertTag, String deleteTag) {
        this.parsingTypes = parsingTypes;
        this.delimiter = delimiter;
        this.insertTag = insertTag;
        this.deleteTag = deleteTag;
    }

    @Override
    public void open(InitializationContext context) throws Exception {

    }

    public static String convert(RowData rowData, LogicalTypeRoot root, int index) {
        switch (root) {
            case INTEGER:
                return Integer.toString(rowData.getInt(index));
            case VARCHAR:
                return rowData.getString(index).toString();
            default:
                throw new IllegalArgumentException();
        }
    }

    @Override
    public byte[] serialize(RowData rowData) {
        int size = parsingTypes.size();
        String[] row = new String[size + 1];
        if (rowData.getRowKind() == RowKind.INSERT) {
            row[0] = insertTag;
        } else if (rowData.getRowKind() == RowKind.DELETE) {
            row[0] = deleteTag;
        } else {
            throw new IllegalArgumentException("unsupported RowKind : " + rowData.getRowKind());
        }

        for (int i = 0; i < size; i++) {
            row[i + 1] = convert(rowData, parsingTypes.get(i).getTypeRoot(), i);
        }

        return String.join(delimiter, row).getBytes(StandardCharsets.UTF_8);
    }
}

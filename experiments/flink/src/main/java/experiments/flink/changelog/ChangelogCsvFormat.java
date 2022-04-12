package experiments.flink.changelog;

import org.apache.flink.api.common.serialization.DeserializationSchema;
import org.apache.flink.api.common.serialization.SerializationSchema;
import org.apache.flink.api.common.typeinfo.TypeInformation;
import org.apache.flink.table.connector.ChangelogMode;
import org.apache.flink.table.connector.format.DecodingFormat;
import org.apache.flink.table.connector.format.EncodingFormat;
import org.apache.flink.table.connector.sink.DynamicTableSink;
import org.apache.flink.table.connector.source.DynamicTableSource;
import org.apache.flink.table.data.RowData;
import org.apache.flink.table.types.DataType;
import org.apache.flink.table.types.logical.LogicalType;
import org.apache.flink.types.RowKind;

import java.util.List;

public class ChangelogCsvFormat implements EncodingFormat<SerializationSchema<RowData>>, DecodingFormat<DeserializationSchema<RowData>> {
    private final String delimiter;
    private final String insertTag;
    private final String deleteTag;

    public ChangelogCsvFormat(String delimiter, String insertTag, String deleteTag) {
        this.delimiter = delimiter;
        this.insertTag = insertTag;
        this.deleteTag = deleteTag;
    }

    @Override
    public SerializationSchema<RowData> createRuntimeEncoder(DynamicTableSink.Context context, DataType physicalDataType) {
        final List<LogicalType> parsingTypes = physicalDataType.getLogicalType().getChildren();

        return new ChangelogCsvSerializer(parsingTypes, delimiter, insertTag, deleteTag);
    }

    @Override
    @SuppressWarnings("unchecked")
    public DeserializationSchema<RowData> createRuntimeDecoder(DynamicTableSource.Context context, DataType physicalDataType) {
        final TypeInformation<RowData> producedTypeInfo = context.createTypeInformation(physicalDataType);

        final DynamicTableSource.DataStructureConverter converter = context.createDataStructureConverter(physicalDataType);

        final List<LogicalType> parsingTypes = physicalDataType.getLogicalType().getChildren();

        return new ChangelogCsvDeserializer(parsingTypes, converter, producedTypeInfo, delimiter, insertTag, deleteTag);
    }

    @Override
    public ChangelogMode getChangelogMode() {
        return ChangelogMode.newBuilder()
                .addContainedKind(RowKind.INSERT)
                .addContainedKind(RowKind.DELETE)
                .build();
    }
}

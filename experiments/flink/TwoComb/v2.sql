CREATE TABLE V2 (
    dst INT,
    ts TIMESTAMP(3),
    WATERMARK FOR ts AS ts
) WITH (
    'connector' = 'filesystem',
    'path' = '${path.to.flink.v2.csv}',
    'format' = 'csv',
    'csv.field-delimiter' = '|'
)
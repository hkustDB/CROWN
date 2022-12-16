CREATE TABLE V1 (
    src INT,
    ts TIMESTAMP(3),
    WATERMARK FOR ts AS ts
) WITH (
    'connector' = 'filesystem',
    'path' = 'flink.v1.csv',
    'format' = 'csv',
    'csv.field-delimiter' = '|'
)
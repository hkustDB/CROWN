CREATE TABLE Graph (
    src INT,
    dst INT,
    ts TIMESTAMP(3),
    WATERMARK FOR ts AS ts
) WITH (
    'connector' = 'filesystem',
    'path' = 'flink.graph.csv',
    'format' = 'csv',
    'csv.field-delimiter' = '|'
)
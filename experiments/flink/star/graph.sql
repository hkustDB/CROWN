CREATE TABLE Graph (
    src INT,
    dst INT,
    ts TIMESTAMP(3),
    WATERMARK FOR ts AS ts
) WITH (
    'connector' = 'filesystem',
    'path' = '${path.to.data.raw}',
    'format' = 'csv'
)
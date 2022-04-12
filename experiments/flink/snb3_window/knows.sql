CREATE TABLE knows (
    ts TIMESTAMP(3),
    k_explicitlyDeleted BOOLEAN NOT NULL,
    k_person1id BIGINT NOT NULL,
    k_person2id BIGINT NOT NULL,
    WATERMARK FOR ts AS ts
) WITH (
    'connector' = 'filesystem',
    'path' = '${path.to.flink.knows.window.csv}',
    'format' = 'csv',
    'csv.field-delimiter' = '|'
)
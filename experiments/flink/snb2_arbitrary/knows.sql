create table knows (
    k_explicitlyDeleted boolean not null,
    k_person1id bigint not null,
    k_person2id bigint not null
) WITH (
    'connector' = 'filesystem',
    'path' = '${path.to.flink.knows.arbitrary.csv}',
    'format' = 'csv-changelog'
)
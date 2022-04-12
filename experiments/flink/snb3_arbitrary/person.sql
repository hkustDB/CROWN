create table person (
   p_explicitlyDeleted boolean not null,
   p_personid bigint not null,
   p_firstname varchar not null,
   p_lastname varchar not null,
   p_gender varchar not null,
   p_birthday date not null,
   p_locationip varchar not null,
   p_browserused varchar not null,
   p_placeid bigint not null,
   p_language varchar not null,
   p_email varchar not null
) WITH (
      'connector' = 'filesystem',
      'path' = '${path.to.flink.person.arbitrary.csv}',
      'format' = 'csv-changelog'
)
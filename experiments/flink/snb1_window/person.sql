create table person (
   ts TIMESTAMP(3),
   p_explicitlyDeleted BOOLEAN NOT NULL,
   p_personid BIGINT NOT NULL,
   p_firstname VARCHAR NOT NULL,
   p_lastname VARCHAR NOT NULL,
   p_gender VARCHAR NOT NULL,
   p_birthday DATE NOT NULL,
   p_locationip VARCHAR NOT NULL,
   p_browserused VARCHAR NOT NULL,
   p_placeid BIGINT NOT NULL,
   p_language VARCHAR NOT NULL,
   p_email VARCHAR NOT NULL,
   WATERMARK FOR ts AS ts
) WITH (
      'connector' = 'filesystem',
      'path' = '${path.to.flink.person.window.csv}',
      'format' = 'csv',
      'csv.field-delimiter' = '|'
)
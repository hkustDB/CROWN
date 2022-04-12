create table tag (
   t_tagid bigint not null,
   t_name varchar not null,
   t_url varchar not null,
   t_tagclassid bigint not null
) WITH (
       'connector' = 'filesystem',
       'path' = '${path.to.flink.tag.window.csv}',
       'format' = 'csv',
       'csv.field-delimiter' = '|'
 )
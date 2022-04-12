create table message_tag (
   ts TIMESTAMP(3),
   mt_messageid bigint not null,
   mt_tagid bigint not null,
   WATERMARK FOR ts AS ts
) WITH (
       'connector' = 'filesystem',
       'path' = '${path.to.flink.messagetag.window.csv}',
       'format' = 'csv',
       'csv.null-literal' = '\N',
       'csv.field-delimiter' = '|'
 )
create table message_tag (
   mt_messageid bigint not null,
   mt_tagid bigint not null
) WITH (
       'connector' = 'filesystem',
       'path' = '${path.to.flink.messagetag.arbitrary.csv}',
       'format' = 'csv-changelog'
 )
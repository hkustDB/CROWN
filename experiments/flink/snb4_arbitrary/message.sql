CREATE TABLE message (
    m_explicitlyDeleted boolean not null,
    m_messageid bigint not null,
    m_ps_imagefile varchar,
    m_locationip varchar not null,
    m_browserused varchar not null,
    m_ps_language varchar,
    m_content varchar,
    m_length int not null,
    m_creatorid bigint not null,
    m_locationid bigint not null,
    m_ps_forumid bigint, -- null for comments
    m_c_parentpostid bigint,
    m_c_replyof bigint -- null for posts
) WITH (
      'connector' = 'filesystem',
      'path' = '${path.to.flink.message.arbitrary.csv}',
      'format' = 'csv-changelog'
)
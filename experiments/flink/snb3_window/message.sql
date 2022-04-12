CREATE TABLE message (
    ts TIMESTAMP(3),
    m_explicitlyDeleted BOOLEAN NOT NULL,
    m_messageid BIGINT NOT NULL,
    m_ps_imagefile VARCHAR,
    m_locationip VARCHAR NOT NULL,
    m_browserused VARCHAR NOT NULL,
    m_ps_language VARCHAR,
    m_content VARCHAR,
    m_length INT NOT NULL,
    m_creatorid BIGINT NOT NULL,
    m_locationid BIGINT NOT NULL,
    m_ps_forumid BIGINT, -- null for comments
    m_c_parentpostid BIGINT,
    m_c_replyof BIGINT, -- null for posts
    WATERMARK FOR ts AS ts
) WITH (
      'connector' = 'filesystem',
      'path' = '${path.to.flink.message.window.csv}',
      'format' = 'csv',
      'csv.null-literal' = '\N',
      'csv.field-delimiter' = '|'
)
create stream message (
    m_explicitlyDeleted varchar,
    m_messageid varchar,
    m_ps_imagefile varchar,
    m_locationip varchar,
    m_browserused varchar,
    m_ps_language varchar,
    m_content varchar,
    m_length int,
    m_creatorid varchar,
    m_locationid varchar,
    m_ps_forumid varchar,
    m_c_parentpostid varchar, 
    m_c_replyof varchar
) 
FROM FILE 'examples/data/snb/messageToaster.csv'
LINE DELIMITED CSV (delimiter := '|');

create stream forum (
   f_explicitlyDeleted varchar,
   f_forumid varchar,
   f_title varchar,
   f_moderatorid varchar 
) FROM FILE 'examples/data/snb/forumToaster.csv'
LINE DELIMITED CSV (delimiter := '|');

create stream person (
   p_explicitlyDeleted varchar,
   p_personid varchar,
   p_firstname varchar,
   p_lastname varchar,
   p_gender varchar,
   p_birthday date,
   p_locationip varchar,
   p_browserused varchar,
   p_placeid varchar,
   p_language varchar,
   p_email varchar 
) FROM FILE 'examples/data/snb/personToaster.csv'
LINE DELIMITED CSV (delimiter := '|');

create stream knows (
   k_explicitlyDeleted varchar,
   k_personid1 varchar,
   k_personid2 varchar 
) FROM FILE 'examples/data/snb/knowsToaster.csv'
LINE DELIMITED CSV (delimiter := '|');

create stream knows2 (
   k_explicitlyDeleted varchar,
   k_personid1 varchar,
   k_personid2 varchar 
) FROM FILE 'examples/data/snb/knowsToaster2.csv'
LINE DELIMITED CSV (delimiter := '|');

create stream tag (
   t_tagid varchar,
   t_name varchar,
   t_url varchar,
   t_tagclassid varchar
) FROM FILE 'examples/data/snb/tag.csv'
LINE DELIMITED CSV (delimiter := '|');

create stream message_tag (
   mt_messageid varchar,
   mt_tagid varchar
) FROM FILE 'examples/data/snb/messageTagToaster.csv'
LINE DELIMITED CSV (delimiter := '|');

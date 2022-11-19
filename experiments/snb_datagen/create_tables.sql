-- tables for raw data
create table message (
    m_creationdate timestamp with time zone not null,
    m_deletionDate timestamp with time zone not null,
    m_explicitlyDeleted boolean not null,
    m_messageid bigint not null,
    m_ps_imagefile varchar,
    m_locationip varchar not null,
    m_browserused varchar not null,
    m_ps_language varchar,
    m_content text,
    m_length int not null,
    m_creatorid bigint not null,
    m_locationid bigint not null,
    m_ps_forumid bigint, -- null for comments
    m_c_parentpostid bigint,
    m_c_replyof bigint -- null for posts
);

create table person (
   p_creationdate timestamp with time zone not null,
   p_deletionDate timestamp with time zone not null,
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
);

create table knows (
   k_creationdate timestamp with time zone not null,
   k_deletionDate timestamp with time zone not null,
   k_explicitlyDeleted boolean not null,
   k_person1id bigint not null,
   k_person2id bigint not null
);

create table message_tag (
   mt_creationdate timestamp with time zone not null,
   mt_deletionDate timestamp with time zone not null,
   mt_messageid bigint not null,
   mt_tagid bigint not null
);

create table tag (
   t_tagid bigint not null,
   t_name varchar not null,
   t_url varchar not null,
   t_tagclassid bigint not null
);

-- tables for arbitrary
create table messageT (
    m_op_time bigint not null,
    m_op int not null,
    m_explicitlyDeleted boolean not null,
    m_messageid bigint not null,
    m_ps_imagefile varchar,
    m_locationip varchar not null,
    m_browserused varchar not null,
    m_ps_language varchar,
    m_content text,
    m_length int not null,
    m_creatorid bigint not null,
    m_locationid bigint not null,
    m_ps_forumid bigint, -- null for comments
    m_c_parentpostid bigint,
    m_c_replyof bigint -- null for posts
);

create table personT (
   p_op_time bigint not null,
   p_op int not null,
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
);

create table knowsT (
   k_op_time bigint not null,
   k_op int not null,
   k_explicitlyDeleted boolean not null,
   k_personid1 bigint not null,
   k_personid2 bigint not null
);

create table message_tagT (
    mt_op_time bigint not null,
    mt_op int not null,
    mt_messageid bigint not null,
    mt_tagid bigint not null
);

-- tables for window
create table messageW (
    m_op_time bigint not null,
    m_op int not null,
    m_explicitlyDeleted boolean not null,
    m_messageid bigint not null,
    m_ps_imagefile varchar,
    m_locationip varchar not null,
    m_browserused varchar not null,
    m_ps_language varchar,
    m_content text,
    m_length int not null,
    m_creatorid bigint not null,
    m_locationid bigint not null,
    m_ps_forumid bigint, -- null for comments
    m_c_parentpostid bigint,
    m_c_replyof bigint -- null for posts
);

create table personW (
   p_op_time bigint not null,
   p_op int not null,
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
);

create table knowsW (
   k_op_time bigint not null,
   k_op int not null,
   k_explicitlyDeleted boolean not null,
   k_personid1 bigint not null,
   k_personid2 bigint not null
);

create table message_tagW (
    mt_op_time bigint not null,
    mt_op int not null,
    mt_messageid bigint not null,
    mt_tagid bigint not null
);
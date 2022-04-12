create table message (
    /*
     * m_ps_ denotes field specific to posts
     * m_c_  denotes field specific to comments
     * other m_ fields are common to posts and messages
     * Note: to distinguish between "post" and "comment" records:
     *   - m_c_replyof IS NULL for all "post" records
     *   - m_c_replyof IS NOT NULL for all "comment" records
     */
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

INSERT INTO messageT 
select extract(EPOCH FROM message.m_creationdate) as m_op_time, 
1 as m_op, 
message.m_explicitlyDeleted, 
message.m_messageid, 
message.m_ps_imagefile,
message.m_locationip,
message.m_browserused,
message.m_ps_language,
message.m_content,
message.m_length,
message.m_creatorid,
message.m_locationid,
message.m_ps_forumid,
message.m_c_parentpostid,
message.m_c_replyof
from message;

INSERT INTO messageT 
select extract(EPOCH FROM message.m_deletionDate) as m_op_time,
0 as m_op, 
message.m_explicitlyDeleted, 
message.m_messageid, 
message.m_ps_imagefile,
message.m_locationip,
message.m_browserused,
message.m_ps_language,
message.m_content,
message.m_length,
message.m_creatorid,
message.m_locationid,
message.m_ps_forumid,
message.m_c_parentpostid,
message.m_c_replyof
from message
where message.m_deletionDate > message.m_creationdate;

\COPY (select * from messageT order by m_op_time asc, m_op desc) to '/home/data/continuous/messageToaster.csv/' DELIMITER '|' csv header ;

\COPY (select m_op, m_op_time, m_explicitlyDeleted, m_messageid, m_ps_imagefile, m_locationip, m_browserused, m_ps_language, m_content, m_length, m_creatorid, m_locationid, m_ps_forumid, m_c_parentpostid,m_c_replyof from messageT order by m_op_time asc, m_op desc) to '/home/data/continuous/message.csv/' DELIMITER '|' csv header ;

create table forumT (
   f_op_time bigint not null,
   f_op int not null,
   f_explicitlyDeleted boolean not null,
   f_forumid bigint not null,
   f_title varchar not null,
   f_moderatorid bigint not null
);

INSERT INTO forumT 
select extract(EPOCH FROM forum.f_creationdate) as f_op_time, 
1 as f_op, 
forum.f_explicitlyDeleted,
forum.f_forumid,
forum.f_title,
forum.f_moderatorid
from forum;

INSERT INTO forumT 
select extract(EPOCH FROM forum.f_deletiondate) as f_op_time, 
0 as f_op, 
forum.f_explicitlyDeleted,
forum.f_forumid,
forum.f_title,
forum.f_moderatorid
from forum;

\COPY (select * from forumT order by f_op_time asc, f_op desc) to '/home/data/continuous/forumToaster.csv/' DELIMITER '|' csv header ;

\COPY (select f_op, f_op_time, f_explicitlyDeleted, f_forumid, f_title, f_moderatorid from forumT order by f_op_time asc, f_op desc) to '/home/data/continuous/forum.csv/' DELIMITER '|' csv header ;

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

INSERT INTO personT 
select extract(EPOCH FROM person.p_creationdate) as p_op_time, 
1 as p_op, 
person.p_explicitlyDeleted,
person.p_personid,
person.p_firstname,
person.p_lastname,
person.p_gender,
person.p_birthday,
person.p_locationip,
person.p_browserused,
person.p_placeid,
person.p_language,
person.p_email
from person;

INSERT INTO personT 
select extract(EPOCH FROM person.p_deletiondate) as p_op_time, 
0 as p_op, 
person.p_explicitlyDeleted,
person.p_personid,
person.p_firstname,
person.p_lastname,
person.p_gender,
person.p_birthday,
person.p_locationip,
person.p_browserused,
person.p_placeid,
person.p_language,
person.p_email
from person;

\COPY (select * from personT order by p_op_time asc, p_op desc) to '/home/data/continuous/personToaster.csv/' DELIMITER '|' csv header ;

\COPY (select p_op, p_op_time, p_explicitlyDeleted, p_personid, p_firstname, p_lastname, p_gender, p_birthday, p_locationip, p_browserused, p_placeid, p_language, p_email from personT order by p_op_time asc, p_op desc) to '/home/data/continuous/person.csv/' DELIMITER '|' csv header ;


create table knowsT (
   k_op_time bigint not null,
   k_op int not null,
   k_explicitlyDeleted boolean not null,
   k_personid1 bigint not null,
   k_personid2 bigint not null
);

INSERT INTO knowsT 
select extract(EPOCH FROM knows.k_creationdate) as k_op_time, 
1 as k_op, 
knows.k_explicitlyDeleted,
knows.k_person1id,
knows.k_person2id
from knows;

INSERT INTO knowsT 
select extract(EPOCH FROM knows.k_deletiondate) as k_op_time, 
0 as k_op, 
knows.k_explicitlyDeleted,
knows.k_person1id,
knows.k_person2id
from knows;

\COPY (select * from knowsT order by k_op_time asc, k_op desc) to '/home/data/continuous/knowsToaster.csv/' DELIMITER '|' csv header ;

\COPY (select k_op, k_op_time, k_explicitlyDeleted, k_personid1, k_personid2 from knowsT order by k_op_time asc, k_op desc) to '/home/data/continuous/knows.csv/' DELIMITER '|' csv header ;

create table message_tagT (
    mt_op_time bigint not null,
    mt_op int not null,
    mt_messageid bigint not null,
    mt_tagid bigint not null
);

INSERT INTO message_tagT 
select extract(EPOCH FROM message_tag.mt_creationdate) as mt_op_time, 
1 as mt_op, 
message_tag.mt_messageid,
message_tag.mt_tagid
from message_tag;

INSERT INTO message_tagT 
select extract(EPOCH FROM message_tag.mt_deletiondate) as mt_op_time, 
0 as mt_op, 
message_tag.mt_messageid,
message_tag.mt_tagid
from message_tag;

\COPY (select * from message_tagT order by mt_op_time asc, mt_op desc) to '/home/data/continuous/messageTagToaster.csv/' DELIMITER '|';

\COPY (select mt_op, mt_op_time, mt_messageid, mt_tagid from message_tagT order by mt_op_time asc, mt_op desc) to '/home/data/continuous/messageTag.csv/' DELIMITER '|';
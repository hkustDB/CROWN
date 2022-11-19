-- first delete all the invalid rows to avoid insert-insert-delete-delete sequence in window experiment

delete from knows as A where exists
(select * from knows as B where B.k_person1id = A.k_person1id
and B.k_person2id = A.k_person2id and B.k_creationdate + interval '90' day > A.k_creationdate
and B.k_creationdate < A.k_creationdate);

delete from message_tag as A where exists
(select * from message_tag as B where B.mt_messageid = A.mt_messageid
and B.mt_tagid = A.mt_tagid and B.mt_creationdate + interval '90' day > A.mt_creationdate
and B.mt_creationdate < A.mt_creationdate);

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

-- table *W = original insertion + a deletion on 180 days later
INSERT INTO messageW
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

INSERT INTO messageW
select (extract(EPOCH FROM message.m_creationdate) + 15552000) as m_op_time,
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
from message;

INSERT INTO personW
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

INSERT INTO personW
select (extract(EPOCH FROM person.p_creationdate) + 15552000) as p_op_time,
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


INSERT INTO knowsW
select extract(EPOCH FROM knows.k_creationdate) as k_op_time,
1 as k_op,
knows.k_explicitlyDeleted,
knows.k_person1id,
knows.k_person2id
from knows;


INSERT INTO knowsW
select (extract(EPOCH FROM knows.k_creationdate) + 15552000) as k_op_time,
0 as k_op,
knows.k_explicitlyDeleted,
knows.k_person1id,
knows.k_person2id
from knows;



INSERT INTO message_tagW
select extract(EPOCH FROM message_tag.mt_creationdate) as mt_op_time,
1 as mt_op,
message_tag.mt_messageid,
message_tag.mt_tagid
from message_tag;


INSERT INTO message_tagW
select (extract(EPOCH FROM message_tag.mt_creationdate) + 15552000) as mt_op_time,
0 as mt_op,
message_tag.mt_messageid,
message_tag.mt_tagid
from message_tag;
select t_name, t_tagid, count(distinct m_messageid)
from tag, message, message_tag, knows
where
    m_messageid = mt_messageid and
    mt_tagid = t_tagid and
    m_creatorid = k_person2id and
    m_c_replyof IS NULL and
    k_person1id < 100000
group by
t_name, t_tagid
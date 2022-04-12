select
    t_name, t_tagid, count(distinct m_messageid)
from tag, messageWindowed, message_tagWindowed, knowsWindowed
where
    m_messageid = mt_messageid and
    mt_tagid = t_tagid and
    m_creatorid = k_person2id and
    m_c_replyof IS NULL and
    k_person1id < 100000 and
    knowsWindowed.window_start = messageWindowed.window_start and
    knowsWindowed.window_start = message_tagWindowed.window_start
group by
t_name, t_tagid
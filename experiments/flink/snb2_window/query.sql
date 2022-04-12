select
    k1.k_person1id, k1.k_person2id, k2.k_person2id, t_tagid, m_messageid,
    k1.window_start, k1.window_end
from tag, messageWindowed, message_tagWindowed, knowsWindowed k1, knowsWindowed k2
where
    m_messageid = mt_messageid and
    mt_tagid = t_tagid and
    k1.k_person2id = k2.k_person1id and
    m_creatorid = k2.k_person2id and
    m_c_replyof IS NULL and 
    k1.k_person1id < 100000 and
    k1.window_start = k2.window_start and
    k1.window_start = messageWindowed.window_start and
    k1.window_start = message_tagWindowed.window_start
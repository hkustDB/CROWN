select k1.k_person1id, k1.k_person2id, k2.k_person2id, t_tagid, m_messageid
from tag, message, message_tag, knows k1, knows k2
where
    m_messageid = mt_messageid and
    mt_tagid = t_tagid and
    k1.k_person2id = k2.k_person1id and
    m_creatorid = k2.k_person2id and
    m_c_replyof IS NULL and 
    k1.k_person1id < 100000
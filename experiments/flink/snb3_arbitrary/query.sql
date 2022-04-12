select p_personid, p_firstname, p_lastname, m_messageid, k1.k_person1id, k1.k_person2id
from person, message, knows k1, knows k2
where
    p_personid = m_creatorid and
    k2.k_person2id = p_personid
    and k1.k_person2id = k2.k_person1id
    and k2.k_person2id <> k1.k_person1id
    and k1.k_person1id < 100000
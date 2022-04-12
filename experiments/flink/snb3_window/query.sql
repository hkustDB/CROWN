SELECT
    p_personid, p_firstname, p_lastname,
    m_messageid, k1.k_person1id, k1.k_person2id,
    personWindowed.window_start,
    personWindowed.window_end
FROM
    personWindowed, messageWindowed, knowsWindowed AS k1, knowsWindowed AS k2
WHERE
    personWindowed.window_start = messageWindowed.window_start
    AND messageWindowed.window_start = k1.window_start
    AND k1.window_start = k2.window_start
    AND k1.k_person1id < 100000
    and k1.k_person2id = k2.k_person1id
    and k2.k_person2id <> k1.k_person1id
    and p_personid = m_creatorid
    and p_personid = k2.k_person2id
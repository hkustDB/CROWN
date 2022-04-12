SELECT
    p_personid,
    p_firstname,
    p_lastname,
    m_messageid,
    k_person1id,
    personWindowed.window_start,
    personWindowed.window_end
FROM
    personWindowed, messageWindowed, knowsWindowed
WHERE
    personWindowed.window_start = messageWindowed.window_start
    AND messageWindowed.window_start = knowsWindowed.window_start
    AND p_personid = m_creatorid
    AND k_person2id = p_personid
SELECT p_personid, p_firstname, p_lastname, m_messageid, k_person1id
FROM
    person, message, knows
WHERE
    p_personid = m_creatorid AND k_person2id = p_personid
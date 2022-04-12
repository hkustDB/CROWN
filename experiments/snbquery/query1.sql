INCLUDE './examples/queries/snb/schemas.sql';

select p_personid, p_firstname, p_lastname, m_messageid, k_personid1
from person, message, knows
where
    p_personid = m_creatorid and
    k_personid2 = p_personid

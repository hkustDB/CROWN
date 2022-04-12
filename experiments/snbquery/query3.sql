INCLUDE './examples/queries/snb/schemas.sql';

select p_personid, p_firstname, p_lastname, m_messageid, k1.k_personid1, k1.k_personid2
from person, message, knows k1, knows k2
where
    p_personid = m_creatorid and
    k2.k_personid2 = p_personid
    and k1.k_personid2 = k2.k_personid1
    and k2.k_personid2 <> k1.k_personid1
    and regexp_match('^.{0,5}$',k1.k_personid1) = 1
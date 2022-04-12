INCLUDE './examples/queries/snb/schemas.sql';

select k1.k_personid1, k1.k_personid2, k2.k_personid2, t_tagid, m_messageid
from tag, message, message_tag, knows k1, knows2 k2
where
    m_messageid = mt_messageid and
    mt_tagid = t_tagid and
    k1.k_personid2 = k2.k_personid1 and
    m_creatorid = k2.k_personid2 and
    regexp_match('^-1$', m_c_replyof) = 1 and
    regexp_match('^.{0,5}$',k1.k_personid1) = 1
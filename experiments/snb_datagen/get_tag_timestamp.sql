select cast(extract(EPOCH FROM uu.mint) as bigint)-1 as mt_op_time from (
select MIN(t) AS mint from
(
	(SELECT MIN(m_creationdate) AS t FROM message) union
	(SELECT MIN(p_creationdate) AS t FROM person) union
	(SELECT MIN(k_creationdate) AS t FROM knows) union
	(SELECT MIN(mt_creationdate) AS t FROM message_tag)
) AS u
) AS uu